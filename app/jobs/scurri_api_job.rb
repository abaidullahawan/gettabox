# frozen_string_literal: true

# Scurri API Calls Job
class ScurriApiJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    order_id = _args.first[:order_id] || _args.first['order_id']
    channel_orders = ChannelOrder.where(id: order_id)

    return unless channel_orders.present?

    url= 'https://api.scurri.co.uk/v1/company/itd-global-gettabox-ltd/consignments/'

    auth = 'Basic S1VCUkFAR0VUVEFCT1guQ09NOkdldHRhYm94LjEyMw=='

    data =
      channel_orders.each.map do |order|
        customer = order.system_user
        delivery_address = customer.addresses.where(address_title: 'delivery').first
        tracking = order.trackings.first
      {
        "carrier" => tracking.carrier,
        "warehouse_id" => "itd-global-gettabox-ltd|ITD Global: GETTABOX LTD",
        "service_id" => carrier_shipping_service(tracking.shipping_service),
        "recipient" => {
          "address" => {
            "country" => delivery_address.country,
            "postcode" => delivery_address.postcode,
            "city" => delivery_address.city,
            "address1" => delivery_address.address,
            "state" => delivery_address.region
          },
          "contact_number" => customer.phone_number,
          "email_address" => customer.email,
          "company_name" => delivery_address.company,
          "name" => delivery_address.name
        },
        "order_number" => order.order_id,
        "options" => {
          "package_type" => "Parcel",
          "signed" => "no"
        },
        "packages" =>
          order.assign_rule.mail_service_labels.each.map do |label|
          {
            "items" => [
              {
                "weight" => label.weight / 1000,
                "value" => order.total_amount,
                "fabric_content" => "Household",
                "country_of_origin" => "GB",
                "sku" => "CB05 - 5010743032058 Big K Charcoal Briquettes 5KG heavy x 3",
                "quantity" => 1,
                "name" => "Real Charcoal Briquettes Char coal For BBQ Barbecue Restaurant Charcoal 5kg-20kg"
              }
            ],
            "length" => label.length,
            "height" => label.height,
            "width" => label.width,
            "reference" => "CustomCustomerReference1"
          }
          end
      }
      end

    response = ScurriApiService.create_shipment(url, data, auth)
    return unless response[:status]

    consignment_id = document_response[:body]['success']
    document_response = consignment_document(consignment_id, auth)
    return 'Document not found' unless document_response[:status]

    document = document_response[:body]['labels']
    File.open(consignment_id, 'wb') do |f|
      f.write(Base64.decode64(document))
    end
  end

  def carrier_shipping_service(shipping_service)
    shipping_services = {
      'yodel direct xpress mini' => 'Yodel|XPRESS MINI 48 NON POD 2CMN',
      'yodel direct xpress 48 pod'=> 'Yodel|XPRESS 48 POD 2CP',
      'yodel direct xpress 48 non pod' => 'Yodel|XPRESS 48 POD 2CP',
      'yodel direct xpress 24 pod' => 'Yodel|XPRESS 24 POD 1CP',
      'yodel direct xpress 24 non pod' => 'Yodel|XPRESS 24 POD 1CP',
      'yodel direct xpect mon - sat pod' => 'Yodel|XPECT 24 POD 1VP',
      'yodel direct xpect mon - sat non pod' => 'Yodel|XPECT 48 POD 2VP',
      'yodel direct xpect 24 pod' => 'Yodel|XPECT 24 POD 1VP',
      'yodel direct xpect 48 pod' => 'Yodel|XPECT 48 POD 2VP',
      'yodel direct xpect 48 non pod' => 'Yodel|XPECT 48 POD 2VP',
      'yodel direct channel islands 48 non pod' => 'Yodel|XPECT 48 POD 2VP',
      'hermes 48' => 'Hermes|UK Standard Delivery',
      'hermes 24' => 'Hermes|UK Standard Delivery',
      'hermes 48 pod' => 'Hermes|UK Standard Delivery',
      'hermes 24 pod' => 'Hermes|UK Standard Delivery',
      'hermes 48 non pod' => 'Hermes|UK Standard Delivery',
      'hermes 24 non pod' => 'Hermes|UK Standard Delivery',
    }
    shipping_services[shipping_service]
  end

  def consignment_document(id, auth)
    url = "https://api.scurri.co.uk/v1/company/itd-global-gettabox-ltd/consignment/#{id}/documents"
    ScurriApiService.consignment_document(url, auth)
  end
end
