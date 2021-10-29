# frozen_string_literal: true

# getting orders response from api
class CreateChannelOrderJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @response_orders = ChannelResponseData.all
    creat_orders = []
    @response_orders.each do |response_order|
      next unless (response_order.api_call == 'getOrders') && (response_order.status == 'panding')

      create_or_update_order(response_order)
      ChannelOrder.import creat_orders, on_duplicate_key_update: [:ebayorder_id]
      response_order.update(status: 'executed')
    end
  end

  def create_or_update_order(response_order)
    response_order.response['orders'].each do |order|
      creationdate = order['creationDate']
      channel_order_record = ChannelOrder.find_or_initialize_by(ebayorder_id: order['orderId'],
                                                                channel_type: 'ebay')
      channel_order_record.order_data = order
      channel_order_record.created_at = creationdate
      creat_orders << channel_order_record
    end
  end
end
