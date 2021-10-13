class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :refresh_token, only: %i[ index ]
  before_action :check_status, only: %i[ index get_response_orders ]

  def index
    @all_orders = ChannelOrder.all
    @orders = @all_orders.order(created_at: :desc).page(params[:page]).per(params[:limit])
    if params[:all_product_data].present?
      all_order_data
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
      ebay_url = "https://api.ebay.com/sell/fulfillment/v1/order?&limit=1000&offset=#{@offset}"
      ChannelResponseData.create_with(channel: "ebay", api_url: ebay_url, api_call: "getOrders", status: "not available").find_or_create_by(api_url: ebay_url, api_call: "getOrders")
      @offset += 1000
      if @offset > @body['total']
        break
      end
    end
    CreateChannelOrderResponseJob.perform_later
    flash[:notice] = "CALL sent to eBay API"
    redirect_to order_dispatches_path
  end

  def get_response_orders
    if @status == 0
      flash[:notice] = "Please CALL eBay Orders."
      redirect_to order_dispatches_path
    else
      CreateChannelOrderJob.perform_later
      flash[:notice] = "eBay Orders are saving . . ."
      redirect_to order_dispatches_path
    end
  end

  private
    def order_mapping_params
    end

    def check_status
      @response_status = ChannelResponseData.all.pluck(:status)
      @status = 1
      @response_status.each do |response_status|
        if ((response_status == "error") || (response_status == "not available"))
          @status = 0
        end
      end
      @status = 3 if (@response_status == [])
    end

end
