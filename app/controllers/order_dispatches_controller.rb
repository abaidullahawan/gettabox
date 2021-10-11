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

    url = ("https://api.ebay.com/sell/fulfillment/v1/order?&limit=1&offset=0")
    headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
    'content-type' => "application/json",
    'accept' => "application/json"
    }

    uri = URI(url)
    request = Net::HTTP.get_response(uri, headers)
    @body = JSON.parse(request.body)
    @offset = 0
    loop do
      ChannelResponseData.create_with(channel: "ebay", api_url: "https://api.ebay.com/sell/fulfillment/v1/order?&limit=1000&offset=#{@offset}", api_call: "getOrders").find_or_create_by(api_url: "https://api.ebay.com/sell/fulfillment/v1/order?&limit=1000&offset=#{@offset}", api_call: "getOrders")
      @offset += 1000
      if @offset > @body['total']
        break
      end
    end
    CreateChannelOrderResponseJob.perform_later
    CreateChannelOrderJob.perform_later
  end

  private
    def order_mapping_params
    end

end
