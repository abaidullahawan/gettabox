# frozen_string_literal: true

# orders for amazon
class AmazonOrderJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token_amazon = RefreshToken.where(channel: 'amazon').last
    data = {
      'MarketplaceIds' => 'A1F83G8C2ARO7P',
      'CreatedAfter' => (Time.zone.now - 24.hours).strftime('%Y-%m-%dT%H:%M:%S')
    }
    url = "https://sellingpartnerapi-eu.amazon.com/orders/v0/orders?" + URI.encode_www_form(data)
    remainaing_time = @refresh_token_amazon.access_token_expiry.localtime > DateTime.now
    generate_refresh_token_amazon if @refresh_token_amazon.present? && remainaing_time == false
    result = AmazonService.amazon_api(@refresh_token_amazon.access_token, url)
    return puts result unless result[:status]

    create_order_response(result, url)
    next_token = result[:body]['payload']['NextToken']
    amazon_orders = ChannelResponseData.where(channel: 'amazon', api_call: 'getOrders', status: 'pending')
    create_amazon_orders(amazon_orders, @refresh_token_amazon.access_token) if amazon_orders.present?
    next_orders_amz(next_token, url, @refresh_token_amazon.access_token) if next_token.present?
  end

  def next_orders_amz(next_token, url, access_token)
    result = AmazonService.next_orders_amz(next_token, access_token, url)
    return puts result unless result[:status]

    create_order_response(result, url)
    amazon_orders = ChannelResponseData.where(channel: 'amazon', api_call: 'getOrders', status: 'pending')
    create_amazon_orders(amazon_orders, access_token) if amazon_orders.present?
    new_next_token = result[:body]['payload']['NextToken']
    next_orders_amz(new_next_token, url, access_token) if new_next_token.present?
  end

  def generate_refresh_token_amazon
    result = RefreshTokenService.amazon_refresh_token(@refresh_token_amazon)
    return update_refresh_token(result[:body], @refresh_token_amazon) if result[:status]
  end

  def update_refresh_token(result, refresh_token)
    refresh_token.update(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds
    )
  end

  def create_order_response(result, url)
    ChannelResponseData.create(
      channel: 'amazon', response: result[:body],
      api_call: 'getOrders', api_url: url, status: 'pending'
    )
  end

  def create_amazon_orders(amazon_orders, access_token)
    amazon_orders.each do |amazon_order|
      amazon_order.response['payload']['Orders'].each do |order|
        channel_order = ChannelOrder.find_or_initialize_by(order_id: order['AmazonOrderId'],
                                                           channel_type: 'amazon')
        if channel_order.id.blank? || channel_order.stage_unpaid? || channel_order.stage_pending?
          next if order['PurchaseDate'] < ('2022-03-10T08:00:00Z').to_datetime

          channel_order.order_data = order
          channel_order.created_at = order['PurchaseDate']
          channel_order.order_status = order['OrderStatus']
          channel_order.stage = order_stage(order['OrderStatus'])
          channel_order.order_type = order['OrderType']
          amount = order['OrderTotal'].nil? ? nil : order['OrderTotal']['Amount']
          channel_order.total_amount = amount.to_f
          channel_order.postage = order['ShipmentServiceLevelCategory']
          channel_order.fulfillment_instruction = order['FulfillmentChannel']
          # customer_records(channel_order) if channel_order.save
          next unless channel_order.save

          add_product(channel_order.order_id, access_token, channel_order.id)
          criteria = channel_order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
          assign_rules = AssignRule.where(criteria: criteria)&.last
          channel_order.update(assign_rule_id: assign_rules.id) if assign_rules.present?
          update_order_stage(channel_order.channel_order_items.map { |i| i.channel_product&.status }, channel_order)
          channel_order.update(stage: 'issue') if channel_order.channel_order_items.map(&:sku).any? nil
          if channel_order.stage == 'unable_to_find_sku' || channel_order.stage == 'unmapped_product_sku' || channel_order.stage == 'ready_to_dispatch'
            channel_order.update(change_log: "Order Paid, #{channel_order.id}, #{channel_order.order_id}, amazon")
          end
        end
        amazon_order.update(status: 'executed')
      end
    end
  end

  def add_product(amazon_order_id, access_token, channel_order_id)
    url = "https://sellingpartnerapi-eu.amazon.com/orders/v0/orders/#{amazon_order_id}/orderItems"
    result = AmazonService.amazon_product_api(url, access_token)
    update_channel_order(result, channel_order_id) if result[:status]
  end

  def update_channel_order(result, channel_order_id)
    result[:body]['payload']['OrderItems'].each do |item|
      channel_item = ChannelOrderItem.find_or_initialize_by(
        channel_order_id: channel_order_id,
        line_item_id: item['ASIN']
      )
      channel_item.sku = item['SellerSKU']
      channel_item.ordered = item['QuantityOrdered']
      channel_item.item_data = item
      channel_item.title = item['Title']
      channel_item.channel_product_id = ChannelProduct.find_by(listing_id: channel_item.line_item_id, item_sku: channel_item.sku, channel_type: 'amazon')&.id || ChannelProduct.find_by(item_sku: channel_item.sku, channel_type: 'amazon')&.id
      channel_item.save
    end
  end

  def customer_records(order)
    url = "https://sellingpartnerapi-eu.amazon.com/orders/v0/orders/#{order.order_id}/buyerInfo"
    result = AmazonService.amazon_api(@refresh_token_amazon.access_token, url)
    return puts result unless result[:status]

    create_customer(result[:body], order)
  end

  def create_customer(result, order)
    customer = SystemUser.find_or_initialize_by(user_type: 'customer', email: result['payload']['BuyerEmail'])
    address = order.order_data['ShippingAddress']
    add_customer_address(customer, address, 'admin')
    # delivery_address = order['ShippingAddress']
    add_customer_address(customer, address, 'delivery')
    customer.sales_channel = 'amazon'
    customer.name = 'Amazon User'
    customer.save
    order.update(system_user_id: customer.id)
  end

  def add_customer_address(customer, address, title)
    return unless address.present?

    customer.addresses.build(address_title: title,
                             address: address['AddressLine1'],
                             city: address['City'],
                             postcode: address['PostalCode']&.upcase,
                             country: 'United Kingdom',
                             region: address['StateOrRegion'])
  end

  def order_stage(order_status)
    stages = {
      'Shipped' => 'completed',
      'Canceled' => 'canceled',
      'Pending' => 'pending'
    }
    stages[order_status]
  end

  def update_order_stage(condition, order)
    return unless order.order_status.eql? 'Unshipped'

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
    required = product.multipack_products.map { |m| m.quantity.to_i * item.ordered }
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
    product.update(change_log: "API, #{item.channel_product.item_sku}, #{item.channel_order.order_id}, Order Paid,
        #{item.channel_product.listing_id}, #{unshipped}, #{product.inventory_balance} ", unshipped: unshipped, unshipped_orders: product.unshipped_orders.to_i + 1,
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
            total_weight = item.channel_product&.product_mapping&.product&.weight.to_i * item.ordered.to_i
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
            if max_postage == 0 && min_postage == 0
              type = rule.rule_value.to_f == total_postage.to_f ? true : false
            else
              type = true if total_postage.to_f <= max_postage && total_postage.to_f >= min_postage || rule.rule_value.to_f == total_postage
            end
          end
        end
        if type == false
          if max_weight == 0 && min_weight == 0
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
              if item.channel_product&.product_mapping&.product&.product_type == 'multiple'
                quantity = item&.ordered
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
                quantity = item&.ordered
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
