# frozen_string_literal: true

# orders for amazon
class AmazonOrderJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token_amazon = RefreshToken.where(channel: 'amazon').last
    url = "https://sellingpartnerapi-eu.amazon.com/orders/v0/orders?MarketplaceIds=A1F83G8C2ARO7P&CreatedAfter=#{Date.yesterday.strftime('%Y-%m-%d')}T17%3A00%3A00"
    remainaing_time = @refresh_token_amazon.access_token_expiry.localtime > DateTime.now
    generate_refresh_token_amazon if @refresh_token_amazon.present? && remainaing_time == false
    result = AmazonService.amazon_api(@refresh_token_amazon.access_token, url)
    return puts result unless result[:status]

    create_order_response(result, url)
    # next_token = result[:body]['payload']['NextToken']
    # next_orders_amz(next_token, access_token, url) if next_token.present?
    amazon_orders = ChannelResponseData.where(channel: 'amazon', api_call: 'getOrders', status: 'pending')
    create_amazon_orders(amazon_orders, @refresh_token_amazon.access_token) if amazon_orders.present?
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
        channel_order.order_data = order
        channel_order.created_at = order['PurchaseDate']
        channel_order.order_status = order['OrderStatus']
        amount = order['OrderTotal'].nil? ? nil : order['OrderTotal']['Amount']
        channel_order.total_amount = amount
        channel_order.fulfillment_instruction = order['FulfillmentChannel']
        customer_records(channel_order) if channel_order.save
        add_product(channel_order.order_id, access_token, channel_order.id)
        criteria = channel_order.channel_order_items.map { |h| [h[:sku], h[:ordered]] }
        assign_rules = AssignRule.where(criteria: criteria)&.last
        channel_order.update(assign_rule_id: assign_rules.id) if assign_rules.present?
      end
      amazon_order.update(status: 'executed')
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
        line_item_id: item['OrderItemId']
      )
      channel_item.sku = item['SellerSKU']
      channel_item.item_data = item
      channel_item.channel_product_id = ChannelProduct.find_by(item_sku: channel_item.sku)&.id
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
                             postcode: address['PostalCode'],
                             country: address['CountryCode'],
                             region: address['StateOrRegion'])
  end
end
