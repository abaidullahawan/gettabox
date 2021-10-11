class CreateChannelOrderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    @response_orders = ChannelResponseData.all
    @response_orders.each do |response_order|
      if response_order.api_call == "getOrders"
        response_order.response['orders'].each do |order|
          creationdate = order["creationDate"]
          record = ChannelOrder.find_by(ebayorder_id: order["orderId"])
          if record.present?
            record.update(channel_type: "ebay", order_data: order, created_at: creationdate)
          else
            ChannelOrder.create(channel_type: "ebay", order_data: order, ebayorder_id: order["orderId"], created_at: creationdate)
          end
        end
      end
    end
  end
end
