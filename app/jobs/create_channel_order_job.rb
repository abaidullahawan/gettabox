# frozen_string_literal: true

# getting orders response from api
class CreateChannelOrderJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @response_orders = ChannelResponseData.where(api_call: 'getOrders', status: 'pending', channel: 'ebay')
    @response_orders.each do |response_order|
      response_order.response['orders'].each do |order|
        creationdate = order['creationDate']
        channel_order_record = ChannelOrder.find_or_initialize_by(order_id: order['orderId'],
                                                                  channel_type: 'ebay')
        channel_order_record.order_data = order
        channel_order_record.created_at = creationdate
        channel_order_record.order_status = order['orderFulfillmentStatus']
        channel_order_record.stage = 'completed' if order['orderFulfillmentStatus'].eql? 'FULFILLED'
        channel_order_record.payment_status = order['paymentSummary']['payments'].last['paymentStatus']
        channel_order_record.total_amount = order['lineItems'][0]['total']['value']
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
        update_order_stage(channel_order_record.channel_order_items.map { |i| i.channel_product&.status }, channel_order_record)
        channel_order_record.update(stage: 'unpaid') if channel_order_record.payment_status.eql? 'UNPAID'
        channel_order_record.update(stage: 'issue') if channel_order_record.channel_order_items.map(&:sku).any? nil
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
    customer.sales_channel = 'ebay'
    customer.phone_number = order.order_data['fulfillmentStartInstructions'][0]['shippingStep']['shipTo']['primaryPhone']['phoneNumber']
    customer.email = order.order_data['fulfillmentStartInstructions'][0]['shippingStep']['shipTo']['email']
    order.update(system_user_id: customer.id) if customer.save
  end

  def update_order_stage(condition, order)
    return unless order.order_status.eql? 'NOT_STARTED'

    if condition.any?(nil)
      order.update(stage: 'unable_to_find_sku')
    elsif condition.any?('unmapped')
      order.update(stage: 'unmapped_product_sku')
    else
      order.update(stage: 'ready_to_dispatch')
      allocate_or_unallocate(order.channel_order_items)
    end
  end

  def allocate_or_unallocate(channel_items)
    channel_items.each do |item|
      product = item.channel_product.product_mapping.product
      next multipack_product(item, product) unless product.product_type.eql? 'single'

      available_stock = product.available_stock.to_f - item.ordered
      update_available_stock(item, product, available_stock, item.ordered)
    end
  end

  def multipack_product(item, product)
    available = product.multipack_products.map { |m| m.child.available_stock.to_i }
    required = product.multipack_products.map { |m| m.quantity.to_i * order_item.ordered.to_i }
    check = available.zip(required).all? { |a, b| a >= b }
    return unless check

    multipack_allocation(item, product)
  end

  def multipack_allocation(item, product)
    product.multipack_products.each do |multipack|
      quantity = multipack.quantity
      child = multipack.child

      available_stock = child.available_stock.to_f - (item.ordered * quantity)
      update_available_stock(item, child, available_stock, (item.ordered * quantity))
    end
  end

  def update_available_stock(item, product, available_stock, ordered)
    if product.available_stock >= item.ordered
      product.update(available_stock: available_stock, allocated_orders: product.allocated_orders.to_i + ordered,
                     change_log: "API, #{item.channel_order.id},
                                  #{item.channel_order.order_id}, Allocated, #{item.channel_product.item_id}")
      item.update(allocated: true)
    else
      item.update(allocated: false)
    end
  end
end
