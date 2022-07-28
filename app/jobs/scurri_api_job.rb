# frozen_string_literal: true

# Scurri API Calls Job
class ScurriApiJob < ApplicationJob
  queue_as :default
  require 'combine_pdf'

  def perform(*_args)
    order_ids = _args.first[:order_ids] || _args.first['order_ids']
    packing_slip = _args.first[:packing_slip] || _args.first['packing_slip']
    channel_orders = ChannelOrder.where(id: order_ids)

    return unless channel_orders.present?

    url = 'https://api.scurri.co.uk/v1/company/itd-global-gettabox-ltd/consignments/'

    auth = 'Basic S1VCUkFAR0VUVEFCT1guQ09NOkdldHRhYm94LjEyMw=='

    data =
      channel_orders.each.map do |order|
        mail_service_rule = order.assign_rule.mail_service_rule
        courier_name = mail_service_rule.courier&.name
        service_name = mail_service_rule.service&.name
        next unless courier_name.eql? 'ITD'

        customer = order.system_user
        delivery_address = customer.addresses.where(address_title: 'delivery').first
        {
          'carrier' => carrier_shipping_service(service_name).try(:[], :carrier),
          'warehouse_id' => 'itd-global-gettabox-ltd|ITD Global: GETTABOX LTD',
          'service_id' => carrier_shipping_service(service_name).try(:[], :service),
          'recipient' => {
            'address' => {
              'country' => delivery_address.country,
              'postcode' => delivery_address.postcode,
              'city' => delivery_address.city,
              'address1' => delivery_address.address
            },
            'contact_number' => customer.phone_number,
            'email_address' => customer.email,
            'company_name' => delivery_address.company,
            'name' => order.buyer_name
          },
          'order_number' => order.order_id,
          'options' => {
            'package_type' => 'Standard parcel',
            'signed' => 'no'
          },
          'packages' =>
            order.assign_rule.mail_service_labels.each.map do |label|
              {
                'items' => [
                  {
                    'weight' => label.weight / 1000,
                    'value' => order.total_amount,
                    'fabric_content' => 'Household',
                    'country_of_origin' => 'GB',
                    'sku' => order.channel_order_items.first&.sku,
                    'quantity' => order.channel_order_items.first&.ordered,
                    'name' => order.channel_order_items.first&.title
                  }
                ],
                'length' => label.length,
                'height' => label.height,
                'width' => label.width,
                'reference' => 'CustomCustomerReference1'
              }
            end
        }
      end

    response = ScurriApiService.create_shipment(url, data, auth)
    return unless response[:status]

    filenames = []
    channel_order_ids = ChannelOrder.where(id: order_ids).pluck(:order_id)
    consignments = response[:body]['success']
    consignments.each_with_index do |consignment, index|

      document_response = consignment_document(consignment, auth)
      next 'Document not found' unless document_response[:status]

      document = document_response[:body]['labels']
      channel_order_id = channel_order_ids.at(index)
      name = "consignment-label-#{DateTime.now}"
      filenames << name if packing_slip.zero?
      path = Rails.root.join('public/uploads', name.to_s)
      File.open(path.to_s, 'wb') do |f|
        f.write(Base64.decode64(document))
      end
      next unless packing_slip.positive?

      pdf_name = "consignment-packing_slip-#{DateTime.now}"
      generate_packing_slip(channel_order_id, pdf_name)

      pdf_name = "#{pdf_name}.pdf"
      path_for_packing_slip = Rails.root.join('public/uploads', pdf_name.to_s)

      filenames << combine_label_and_packing_slip(path, path_for_packing_slip)
      File.delete(path)
      File.delete(path_for_packing_slip)
    end
    not_delete_file = combine_files(filenames, packing_slip)
    filenames.each do |filename|
      next if filename == not_delete_file

      path = Rails.root.join('public/uploads', filename.to_s)
      File.delete(path)
    end
  end

  def carrier_shipping_service(shipping_service)
    shipping_services = {
      'UK Standard Delivery' => { carrier: 'Hermes', service: 'Hermes|UK Standard Delivery' },
      'UK Next Day Delivery' => { carrier: 'Hermes', service: 'Hermes|UK Next Day Delivery' },
      'XPECT 24 POD (1VP)' => { carrier: 'Yodel', service: 'Yodel|XPECT 24 POD 1VP' },
      'XPECT 48 POD (2VP)' => { carrier: 'Yodel', service: 'Yodel|XPECT 48 POD 2VP' },
      'XPRESS 24 POD (1CP)' => { carrier: 'Yodel', service: 'Yodel|XPRESS 24 POD 1CP' },
      'XPRESS 48 POD (2CP)' => { carrier: 'Yodel', service: 'Yodel|XPRESS 48 POD 2CP' },
      'XPRESS MINI 48 NON POD (2CMN)' => { carrier: 'Yodel', service: 'Yodel|XPRESS MINI 48 NON POD 2CMN' }
    }
    shipping_services[shipping_service]
  end

  def consignment_document(id, auth)
    url = "https://api.scurri.co.uk/v1/company/itd-global-gettabox-ltd/consignment/#{id}/documents"
    ScurriApiService.consignment_document(url, auth)
  end

  def generate_packing_slip(channel_order_id, pdf_name)
    order = ChannelOrder.joins(:channel_order_items, system_user: :addresses)
                        .includes(:channel_order_items, system_user: :addresses)
                        .find_by('channel_orders.order_id': channel_order_id)
    html = PickAndPacksController.new.render_to_string(
      template: 'pick_and_packs/consignement.pdf.erb',
      locals: { order: order }
    )
    pdf = WickedPdf.new.pdf_from_string(
      html,
      pdf: pdf_name,
      layout: 'print',
      page_size: 'A6',
      encoding: 'utf-8'
    )
    pdf_name = "#{pdf_name}.pdf"
    pdf_path = Rails.root.join('public/uploads', pdf_name)
    # create a new file
    File.open(pdf_path, 'wb') do |file|
      file.binmode
      file << pdf.force_encoding('UTF-8')
    end
  end

  def combine_label_and_packing_slip(path, path_for_packing_slip)
    name = "consignment-label-packing-slip-#{DateTime.now}"
    save_path = Rails.root.join('public/uploads', name.to_s)
    pdf = CombinePDF.new
    pdf << CombinePDF.load(path_for_packing_slip)
    pdf << CombinePDF.load(path)
    pdf.save save_path
    name
  end

  def combine_files(filenames, packing_slip)
    name = packing_slip.positive? ? "consignment-label-packing-slip-#{DateTime.now}" : "consignment-label-#{DateTime.now}"
    save_path = Rails.root.join('public/uploads', name.to_s)
    pdf = CombinePDF.new
    filenames.each do |filename|
      path = Rails.root.join('public/uploads', filename.to_s)
      pdf << CombinePDF.load(path)
    end
    pdf.save save_path
    name
  end
end
