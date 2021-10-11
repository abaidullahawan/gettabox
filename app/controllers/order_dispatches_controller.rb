class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :refresh_token, only: %i[ index ]

  def index
    @all_orders = ChannelOrder.all
    @orders = @all_orders.order(created_at: :desc).page(params[:page]).per(params[:limit])
    if params[:all_product_data].present?
      all_order_data
      flash[:notice] = 'All orders are displaying'
      redirect_to order_dispatches_path
    end
  end

  def show
  end

  def create
  end

  def all_order_data
    require 'uri'
    require 'net/http'
    @offset = 0
    @total_order = 0
    loop do
      url = ("https://api.ebay.com/sell/fulfillment/v1/order?&limit=1000&offset=#{@offset}")
      headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
                  'content-type' => "application/json",
                  'accept' => "application/json"
                  }
      uri = URI(url)
      request = Net::HTTP.get_response(uri, headers)
      @body = JSON.parse(request.body)
      # if body["orders"].present?
      #   body["orders"].each do |item|
      #     creationdate = item["creationDate"]
      #     ChannelOrder.create_with(channel_type: "ebay", order_data: item, ebayorder_id: item["orderId"], created_at: creationdate).find_or_create_by(channel_type: "ebay", ebayorder_id: item["orderId"])
      #   end
      # end

      channel_response = ChannelResponseData.new(channel: "ebay", response: @body, api_url: url, api_call: "getOrders")
      if channel_response.save
        @total_order = @body['total']
        @offset += 1000
        if @total_order.nil? || @offset > @total_order
          break
        end
      end
    end
  end

  private
    def order_mapping_params
    end

end
