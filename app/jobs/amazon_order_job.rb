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
        channel_order = ChannelOrder.find_or_initialize_by(ebayorder_id: order['AmazonOrderId'],
                                                           channel_type: 'amazon')
        channel_order.order_data = order
        channel_order.created_at = order['PurchaseDate']
        channel_order.order_status = order['OrderStatus']
        amount = order['OrderTotal'].nil? ? nil : order['OrderTotal']['Amount']
        channel_order.total_amount = amount
        address = "#{order['ShippingAddress']['PostalCode']} #{order['ShippingAddress']['City']} #{order['ShippingAddress']['CountryCode']}" if order['ShippingAddress'].present?
        channel_order.address = address
        channel_order.save
        add_product(channel_order.ebayorder_id, access_token, channel_order.id)
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
      channel_item.save
    end
  end
end
