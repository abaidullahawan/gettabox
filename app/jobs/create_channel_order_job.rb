class CreateChannelOrderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    @response_orders = ChannelResponseData.all
    creat_orders = []
    @response_orders.each do |response_order|
      if ((response_order.api_call == "getOrders") && (response_order.status == "panding"))
        response_order.response['orders'].each do |order|
          creationdate = order["creationDate"]
          channel_order_record = ChannelOrder.find_or_initialize_by(ebayorder_id: order["orderId"], channel_type: "ebay")
          channel_order_record.order_data = order
          channel_order_record.created_at = creationdate
          creat_orders << channel_order_record
        end
        ChannelOrder.import creat_orders, on_duplicate_key_update: [:ebayorder_id]
        response_order.update(status: "executed")
      end
    end
  end
end

# class CreateChannelOrderJob < ApplicationJob
#   queue_as :default

#   def perform(*args)
#     @response_orders = ChannelResponseData.all
#     creat_orders = []
#     @response_orders.each do |response_order|
#       if ((response_order.api_call == "getOrders") && (response_order.status == "panding"))
#         response_order.response['orders'].each do |order|
#           creationdate = order["creationDate"]
#           order_record = ChannelOrder.find_by(ebayorder_id: order["orderId"])
#           if order_record.present?
#             order_record.update(order_data: order, created_at: creationdate)
#           else
#             channel_order_record = ChannelOrder.new(ebayorder_id: order["orderId"], channel_type: "ebay", order_data: order, created_at: creationdate)
#             creat_orders << channel_order_record
#           end
#         end
#         ChannelOrder.import creat_orders, on_duplicate_key_update: [:ebayorder_id]
#         response_order.update(status: "executed")
#       end
#     end
#   end
# end

