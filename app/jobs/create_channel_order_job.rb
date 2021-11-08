# frozen_string_literal: true

# getting orders response from api
class CreateChannelOrderJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @response_orders = ChannelResponseData.where(api_call: 'getOrders', status: 'pending')
    @response_orders.each do |response_order|
      response_order.response['orders'].each do |order|
        creationdate = order['creationDate']
        channel_order_record = ChannelOrder.find_or_initialize_by(ebayorder_id: order['orderId'],
                                                                  channel_type: 'ebay')
        channel_order_record.order_data = order
        channel_order_record.created_at = creationdate
        channel_order_record.order_status = order['orderFulfillmentStatus']
        channel_order_record.payment_status = order["paymentSummary"]["payments"].last["paymentStatus"]
        channel_order_record.save
        channel_order_record.order_data['lineItems'].each do |order_product|
          channel_order_item = ChannelOrderItem.find_or_initialize_by(line_item_id: order_product['lineItemId'])
          channel_order_item.channel_order_id = channel_order_record.id
          channel_order_item.sku = order_product['sku']
          channel_order_item.item_data = order_product
          channel_order_item.save
        end
      end
      response_order.status_executed!
      response_order.status_partial! if response_order.response['orders'].count < 200
    end
  end
end
