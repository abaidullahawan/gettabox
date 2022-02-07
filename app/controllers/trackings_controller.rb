# frozen_string_literal: true

# Order Tracking
class TrackingsController < ApplicationController
  include ImportExport

  before_action :klass_import, only: %i[import]

  def create
    # byebug
  end

  def new
    # byebug
  end

  def import
    return unless @csv.present?

    @csv.delete('id')
    @csv.delete('created_at')
    @csv.delete('updated_at')
    courier_csv_export(@csv)
    # flash[:notice] = 'File Upload Successful!'
  end

  private

  def csv_create_records(csv)
    rows = []
    csv.each do |row|
      order_id = row['order_id'].nil? ? row['channel_order_id'] : ChannelOrder.find_by(order_id: row['order_id'])&.id
      next unless order_ids.include?(order_id)

      tracking_numbers = row['tracking_no'].split(',')
      message = []
      tracking_numbers.each do |number|
        tracking = Tracking.find_or_initialize_by(tracking_no: number, channel_order_id: order_id)
        note = tracking.save ? 'Tracking uploaded successfully' : tracking.errors.full_messages
        message << note
      end
      row = row.to_h.reject { |key, _| key.nil? }
      row['message'] = message
      rows << row
    end
    if rows.empty?
      flash[:alert] = "Selected order's tracking not found"
      redirect_to order_dispatches_path(order_filter: 'ready')
    else
      generate_csv(rows)
    end
  end

  def generate_csv(rows)
    @csv = CSV.generate(headers: true) do |csv|
      csv << %w[Reference Name Quantity SKU Tracking Message]
      rows.each do |row|
        csv << row
      end
    end
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data @csv, filename: "tracking-reponse-#{Date.today}.csv" }
    end
  end

  def courier_csv_export(tracking_csv)
    rows = []
    order_ids = session[:order_ids].split(',')
    # @export_mapping = ExportMapping.find_by(id: params[:export_id])
    # return redirect_response if @export_mapping.nil?

    # to_be_ignored = %w[id user_type selected created_at updated_at]
    # channel_order_data = {}
    # channel_order_item_data = {}
    # address_data = {}
    # system_user_data = {}
    # mail_service_label_data = {}
    # @export_mapping.mapping_data.compact_blank.each do |key, attribute|
    #   channel_order_data[key] = attribute if ChannelOrder.column_names.include? attribute
    #   channel_order_item_data[key] = attribute if ChannelOrderItem.column_names.excluding(to_be_ignored).include? attribute
    #   address_data[key] = attribute if Address.column_names.excluding(to_be_ignored).include? attribute
    #   system_user_data[key] = attribute if SystemUser.column_names.excluding(to_be_ignored).include? attribute
    #   mail_service_label_data[key] = attribute if MailServiceLabel.column_names.excluding(to_be_ignored).include? attribute
    # end
    # attributes = channel_order_data.keys + channel_order_item_data.keys + system_user_data.keys + address_data.keys + mail_service_label_data.keys + ['Tracking']
    tracking_csv.each do |row|
      order_id = row['order_id'].nil? ? row['channel_order_id'] : ChannelOrder.find_by(order_id: row['order_id'])&.id
      next unless order_ids.include?(order_id.to_s)

      tracking_numbers = row['tracking_no'].split(',')
      message = []
      tracking_numbers.each do |number|
        tracking = Tracking.find_or_initialize_by(tracking_no: number, channel_order_id: order_id)
        note = tracking.save ? tracking.tracking_no : tracking.errors.full_messages
        message << note
      end
      order = ChannelOrder.find_by(id: order_id)
      row = []
      row << order.id << order.buyer_name << order.channel_order_items.pluck(:ordered).sum
      row << order.channel_order_items.pluck(:sku) << order.trackings&.pluck(:tracking_no) << message
      rows << row
    end
    ids = rows.map { |row| row[0].to_s } # Change the index if row zero index changes
    (order_ids - ids).each do |order_id|
      order = ChannelOrder.find_by(id: order_id)
      row = []
      row << order.id << order.buyer_name << order.channel_order_items.pluck(:ordered).sum
      row << order.channel_order_items.pluck(:sku) << order.trackings&.pluck(:tracking_no) << 'Tracking not found'
      rows << row
    end
    if rows.empty?
      flash[:alert] = "Selected order's tracking not found"
      redirect_to order_dispatches_path(order_filter: 'ready')
    elsif rows.flatten.any? { |a| a.to_s.include?('must') || a.to_s.include?('not found') }
      generate_csv(rows)
    else
      update_batch(order_ids)
      multiple_products = ChannelOrderItem.where(channel_order_id: order_ids).joins(channel_product: [product_mapping: :product]).where("products.product_type": "multiple").uniq
      single_products = ChannelOrderItem.where(channel_order_id: order_ids).joins(channel_product: [product_mapping: :product]).where("products.product_type": "single").uniq

      products = []
      multiple_products.each do |multiple_product|
        multiple_product.channel_product.product_mapping.product.multipack_products.each do |multi|
          product = multi.child
          quantity = multi.quantity.to_f * (product.pack_quantity.nil? ? 1 : product.pack_quantity.to_f)
          products << { sku: product.sku, product: product, quantity: quantity * multiple_product.ordered }
        end
      end

      single_products.each do |single_product|
        product = single_product.channel_product.product_mapping.product
        quantity = single_product.ordered * (product.pack_quantity.nil? ? 1 : product.pack_quantity.to_f)
        products << { sku: product.sku, product: product, quantity: quantity }
      end

      @products_group = products.group_by { |d| d[:sku] }
      request.format = 'pdf'
      respond_to do |format|
        format.pdf do
          render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'order_dispatches/channel_product.pdf.erb'
        end
      end
    end
    # @csv = CSV.generate(headers: true) do |csv|
    #   csv << attributes
    #   orders.each do |order|
    #     next unless order.assign_rule.mail_service_rule.export_mapping_id == rule

    #     order.update(stage: 'ready_to_print')
    #     order_csv = channel_order_data.values.map { |attr| order.send(attr) }
    #     item_csv = channel_order_item_data.values.map { |attr| order.channel_order_items.first.send(attr) }
    #     address_csv = address_data.values.map { |attr| order.system_user&.addresses&.find_by(address_title: 'delivery')&.send(attr) }
    #     system_user_csv = system_user_data.values.map { |attr| order.system_user&.send(attr) }
    #     label_csv = mail_service_label_data.values.map { |attr| order.assign_rule.mail_service_labels.first.send(attr) }
    #     csv << order_csv + item_csv + system_user_csv + address_csv + label_csv
    #   end
    # end
    # request.format = 'csv'
    # respond_to do |format|
    #   format.csv { send_data @csv, filename: "#{rule_name}.csv" }
    # end
    # flash[:alert] = 'Courier CSV Export Done!'
  end

  def update_batch(order_ids)
    batch = OrderBatch.find_or_initialize_by(batch_name: session[:batch_params]['batch_name'])
    batch.update(session[:batch_params])
    order_ids.each do |id|
      ChannelOrder.find_by(id: id)
                .update(stage: 'ready_to_print', order_batch_id: batch.id, change_log: 'Order Exported')
    end
  end

  def redirect_response
    flash[:alert] = 'Please select orders'
    redirect_to order_dispatches_path(order_filter: 'ready')
  end
end
