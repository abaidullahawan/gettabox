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
    url = ('https://api.ebay.com/sell/fulfillment/v1/order?&limit=1000&offset=0')
    headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
                 'content-type' => "application/json",
                 'accept' => "application/json"
                }
    uri = URI(url)
    request = Net::HTTP.get_response(uri, headers)
    body = JSON.parse(request.body)
    if body.present?
      ChannelResponseData.create(channel: "ebay", response: body, api_url: url, api_call: "getOrders")
    end
    if body["next"].present?
      remaining_data(headers,body["next"])
    else
      respond_to do |format|
        format.html
      end
    end

  end

  def remaining_data(headers,url)
    url = url
    headers = headers
    uri = URI(url)
    request = Net::HTTP.get_response(uri, headers)
    body = JSON.parse(request.body)
    if body.present?
      ChannelResponseData.create(channel: "ebay", response: body, api_url: url, api_call: "getOrders")
    end
    if body["next"].present?
      remaining_data(headers,body["next"])
    else
      respond_to do |format|
        format.html
      end
    end
  end

  private
    def order_mapping_params
    end

end
