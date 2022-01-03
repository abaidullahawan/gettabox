# frozen_string_literal: true

# getting orders response from api
class CreateChannelOrderJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @response_orders = ChannelResponseData.where(api_call: 'getOrders', status: 'pending', channel: 'ebay')
    @response_orders.each do |response_order|
      response_order.response['orders'].each do |order|
        creationdate = order['creationDate']
        channel_order_record = ChannelOrder.find_or_initialize_by(ebayorder_id: order['orderId'],
                                                                  channel_type: 'ebay')
        channel_order_record.order_data = order
        channel_order_record.created_at = creationdate
        channel_order_record.order_status = order['orderFulfillmentStatus']
        channel_order_record.payment_status = order['paymentSummary']['payments'].last['paymentStatus']
        channel_order_record.total_amount = order['lineItems'][0]['total']['value']
        contact_address = order['fulfillmentStartInstructions'][0]['shippingStep']['shipTo']['contactAddress']
        address = "#{contact_address['addressLine1']} #{contact_address['city']} #{contact_address['postalCode']}"
        channel_order_record.address = address
        channel_order_record.buyer_name = order['fulfillmentStartInstructions'][0]['shippingStep']['shipTo']['fullName']&.capitalize
        channel_order_record.buyer_username = order['buyer']['username']
        channel_order_record.fulfillment_instruction = order['fulfillmentStartInstructions'][0]['shippingStep']['shippingServiceCode']
        customer_records(channel_order_record) if channel_order_record.save
        channel_order_record.order_data['lineItems'].each do |order_product|
          channel_order_item = ChannelOrderItem.find_or_initialize_by(line_item_id: order_product['lineItemId'])
          channel_order_item.channel_order_id = channel_order_record.id
          channel_order_item.sku = order_product['sku']
          channel_order_item.channel_product_id = ChannelProduct.find_by(item_sku: channel_order_item.sku)&.id
          channel_order_item.item_data = order_product
          channel_order_item.ordered = order_product['quantity']
          channel_order_item.save
        end
        criteria = channel_order_record.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
        assign_rules = AssignRule.where(criteria: criteria)&.last
        channel_order_record.update(assign_rule_id: assign_rules.id) if assign_rules.present?
      end
      response_order.status_executed!
      response_order.status_partial! if response_order.response['orders'].count < 200
    end
  end

  def customer_records(order)
    customer = SystemUser.find_or_initialize_by(user_type: 'customer', name: order.order_data['buyer']['username'])
    address = order.order_data['buyer']['taxAddress']
    if address.present?
      customer.addresses.build(address_title: 'admin',
                               country: address['countryCode'],
                               region: address['stateOrProvince'],
                               postcode: address['postalCode'])
    end
    order.order_data['fulfillmentStartInstructions'].each do |delivery_address|
      cust_add = delivery_address['shippingStep']['shipTo']['contactAddress']
      next unless cust_add.present?

      customer.addresses.build(address_title: 'delivery',
                               address: cust_add['addressLine1'],
                               city: cust_add['city'],
                               postcode: cust_add['postalCode'],
                               country: cust_add['countryCode'],
                               region: cust_add['stateOrProvince'])
    end
    customer.save
    customer.build_extra_field_value(field_value: {'Sales Channel': 'Gettabox eBay UK'}) if customer.new_record?
    order.update(system_user_id: customer.id)
  end
end
