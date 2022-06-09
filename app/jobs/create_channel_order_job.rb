# frozen_string_literal: true

# getting orders response from api
class CreateChannelOrderJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @response_orders = ChannelResponseData.where(api_call: 'getOrders', status: 'pending', channel: 'ebay')
    @response_orders.each do |response_order|
      response_order.response['orders'].each do |order|
        creationdate = order['creationDate']
        next if creationdate < ('2022-03-10T08:00:00Z').to_datetime
        channel_order_record = ChannelOrder.find_or_initialize_by(order_id: order['orderId'],
                                                                  channel_type: 'ebay')
        if channel_order_record.id.blank? || channel_order_record.stage_unpaid? || channel_order_record.stage_pending?
          channel_order_record.order_data = order
          channel_order_record.created_at = creationdate
          channel_order_record.order_status = order['orderFulfillmentStatus']
          channel_order_record.stage = 'completed' if order['orderFulfillmentStatus'].eql? 'FULFILLED'
          channel_order_record.payment_status = order['paymentSummary']['payments'].last['paymentStatus']
          channel_order_record.total_amount = order['pricingSummary']['total']['value']
          channel_order_record.postage = order['pricingSummary']['deliveryCost']['value']
          channel_order_record.buyer_name = order['fulfillmentStartInstructions'][0]['shippingStep']['shipTo']['fullName']&.capitalize
          channel_order_record.buyer_username = order['buyer']['username']
          channel_order_record.fulfillment_instruction = order['fulfillmentStartInstructions'][0]['shippingStep']['shippingServiceCode']
          customer_records(channel_order_record) if channel_order_record.save
          channel_order_record.order_data['lineItems'].each do |order_product|
            channel_order_item = ChannelOrderItem.find_or_initialize_by(line_item_id: order_product['legacyItemId'], channel_order_id: channel_order_record.id)
            channel_order_item.sku = order_product['sku']
            channel_order_item.title = order_product['title']
            channel_order_item.channel_product_id = ChannelProduct.find_by(listing_id: channel_order_item.line_item_id, item_sku: channel_order_item.sku, channel_type: 'ebay')&.id
            channel_order_item.item_data = order_product
            channel_order_item.ordered = order_product['quantity']
            channel_order_item.save
          end
          criteria = channel_order_record.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
          assign_rules = AssignRule.where(criteria: criteria)&.last
          channel_order_record.update(assign_rule_id: assign_rules.id) if assign_rules.present?
          update_order_stage(channel_order_record.channel_order_items.map do |i|
                              i.channel_product&.status
                            end, channel_order_record)
          channel_order_record.update(stage: 'unpaid') if channel_order_record.payment_status.eql? 'UNPAID'
          channel_order_record.update(stage: 'issue') if channel_order_record.channel_order_items.map(&:sku).any? nil
          if channel_order_record.payment_status == 'PAID'
            channel_order_record.update(change_log: "Order Paid, #{channel_order_record.id}, #{channel_order_record.order_id}, ebay")
          end
        end
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
                               country: 'United Kingdom',
                               region: address['stateOrProvince'],
                               postcode: address['postalCode']&.upcase)
    end
    order.order_data['fulfillmentStartInstructions'].each do |delivery_address|
      cust_add = delivery_address['shippingStep']['shipTo']['contactAddress']
      next unless cust_add.present?

      customer.addresses.build(address_title: 'delivery',
                               name: delivery_address['shippingStep']['shipTo']['fullName'],
                               company: cust_add['addressLine1'],
                               address: cust_add['addressLine2'],
                               city: cust_add['city'],
                               postcode: cust_add['postalCode']&.upcase,
                               country: 'United Kingdom',
                               region: cust_add['stateOrProvince'])
    end
    customer.sales_channel = 'ebay'
    customer.phone_number = order.order_data['fulfillmentStartInstructions'][0]['shippingStep']['shipTo']['primaryPhone']['phoneNumber']
    customer.email = order.order_data['fulfillmentStartInstructions'][0]['shippingStep']['shipTo']['email']
    order.update(system_user_id: customer.id) if customer.save
  end

  def update_order_stage(condition, order)
    return unless order.order_status.eql? 'NOT_STARTED'

    if order.stage != 'completed' && order.stage != 'ready_to_print' && order.stage != 'ready_to_dispatch'
      if condition.any?(nil)
        order.update(stage: 'unable_to_find_sku')
      elsif condition.any?('unmapped')
        order.update(stage: 'unmapped_product_sku')
      else
        order.update(stage: 'ready_to_dispatch')
        allocate_or_unallocate(order.channel_order_items)
        assign_rule(order)
      end
    end
  end

  def allocate_or_unallocate(channel_items)
    channel_items.each do |item|
      product = item.channel_product.product_mapping.product
      if product.present?
        next multipack_product(item, product) unless product.product_type.eql? 'single'

        inventory_balance = product.inventory_balance.to_f - item.ordered
        update_available_stock(item, product, inventory_balance, item.ordered)
      end
    end
  end

  def multipack_product(item, product)
    available = product.multipack_products.map { |m| m.child.available_stock.to_i }
    required = product.multipack_products.map { |m| m.quantity.to_i * item.ordered.to_i }
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

  def update_available_stock(item, product, inventory_balance, ordered)
    unshipped = product.unshipped + ordered if product.unshipped.present?
    channel_type = item.channel_order.channel_type
    product.update(change_log: "API, #{item.channel_product.item_sku}, #{item.channel_order.order_id}, Order Paid, 
        #{item.channel_product.listing_id}, #{channel_type}", unshipped: unshipped, unshipped_orders: product.unshipped_orders.to_i + 1,
        inventory_balance: inventory_balance)
    if product.inventory_balance >= ordered
      product.update(allocated: product.allocated.to_i + ordered, allocated_orders: product.allocated_orders.to_i + 1)
      item.update(allocated: true)
    else
      item.update(allocated: false)
    end
  end

  def assign_rule(order)
    unless order.assign_rule&.save_later

      no_rule = false
      total_weight = 0
      total_postage = order.postage.to_f
      rule_bonus_score = {}
      carrier_type_multi = []
      type = false
      equal = false
      carrier_type = nil
      order.channel_order_items.each do |item|
        if item.channel_product&.product_mapping.present?
          if item.channel_product&.product_mapping&.product&.product_type == 'multiple'
            item.channel_product&.product_mapping&.product&.multipack_products&.each do |multipack_product|
              carrier_type_multi.push(multipack_product.child&.courier_type)
              total_weight += multipack_product.child.weight.to_i * multipack_product.quantity.to_i * item.ordered.to_i
            end
          else
            carrier_type = item.channel_product&.product_mapping&.product&.courier_type
            total_weight = item.channel_product&.product_mapping&.product&.weight.to_i * item&.ordered.to_i
          end
        end
      end
      carrier_type_multi.map {|v| v.downcase! if v.is_a? String}
      if carrier_type.blank?
        carrier_type = (carrier_type_multi&.include? 'hermes') ? 'hermes' : (carrier_type_multi&.include? 'yodal') ? 'yodal' : carrier_type_multi&.last
      end
      MailServiceRule.all.each do |mail_rule|
        min_weight = 0
        max_weight = 0
        min_postage = 0
        max_postage = 0
        mail_rule.rules.each do |rule|
          if rule.rule_field == 'weight_in_gm'
            operator = rule.rule_operator
            case operator
            when 'greater_then'
              min_weight = rule.rule_value.to_i + 1
            when 'greater_then_equal'
              min_weight = rule.rule_value.to_i
            when 'less_then_equal'
              max_weight = rule.rule_value.to_i
            when 'less_then'
              max_weight = rule.rule_value.to_i - 1
            end
          elsif rule.rule_field == 'carrier_type'
            operator = rule.rule_operator
            type = (operator == 'equals' && rule&.rule_value&.downcase == carrier_type&.downcase) ? true : false
          elsif rule.rule_field == 'postage'
            operator = rule.rule_operator
            case operator
            when 'greater_then'
              min_postage = rule.rule_value.to_f + 0.1
            when 'greater_then_equal'
              min_postage = rule.rule_value.to_f
            when 'less_then_equal'
              max_postage = rule.rule_value.to_f
            when 'less_then'
              max_postage = rule.rule_value.to_f - 0.1
            when 'equals'
              equal  = true
            end
            if max_postage.zero? && min_postage.zero?
              type = rule.rule_value.to_f == total_postage.to_f ? true : false
            else
              type = true if total_postage.to_f <= max_postage && total_postage.to_f >= min_postage || rule.rule_value.to_f == total_postage
            end
          end
        end
        if type == false
          if max_weight.zero? && min_weight.zero?
            type = false
          else
            type = true if total_weight.to_i <= max_weight && total_weight.to_i >= min_weight || min_weight > 0 && max_weight == 0 && mail_rule.rules.count.to_i < 2 && total_weight.to_i >= min_weight
          end
        end
        rule_bonus_score[mail_rule.bonus_score.to_i] = mail_rule.id if type
        no_rule = true if type
        type = false
        if no_rule
          if rule_bonus_score.max&.last.present?
            mail_rule_id = rule_bonus_score.max&.last
            assign_rule = AssignRule.create(mail_service_rule_id: mail_rule_id)
            order&.channel_order_items&.each do |item|
              quantity = item&.ordered
              if item.channel_product&.product_mapping&.product&.product_type == 'multiple'
                length = 0
                weight = 0
                width = 0
                height = 0
                item.channel_product&.product_mapping&.product&.multipack_products.each do |multipack_product|
                  length += multipack_product.child.length.to_f * quantity * multipack_product.quantity
                  weight += multipack_product.child.weight.to_f * quantity * multipack_product.quantity
                  width += multipack_product.child.width.to_f
                  height += multipack_product.child.height.to_f
                end
                @service_label = MailServiceLabel.create(height: height, weight: weight,
                                                        length: length, width: width, assign_rule_id: assign_rule.id)
              else
                length = item&.channel_product&.product_mapping&.product&.length.to_f * quantity
                weight = item&.channel_product&.product_mapping&.product&.weight.to_f * quantity
                width = item&.channel_product&.product_mapping&.product&.width.to_f
                height = item&.channel_product&.product_mapping&.product&.height.to_f
                @service_label = MailServiceLabel.create(height: height, weight: weight,
                                                        length: length, width: width, assign_rule_id: assign_rule.id)
              end
            end
            order.update(total_weight: total_weight) if order.total_weight.nil?
            order.update(assign_rule_id: assign_rule.id)
          end
        else
          order.update(total_weight: total_weight) if order.total_weight.nil?
          order.update(assign_rule_id: nil)
        end
      end
    end
  end
end
