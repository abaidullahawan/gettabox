class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :refresh_token, only: %i[ index all_order_data ]
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
    # CreateChannelOrderResponseJob.perform_later
    require 'uri'
    require 'net/http'
    @refresh_token = RefreshToken.last

    url = ("https://api.ebay.com/sell/fulfillment/v1/order?&limit=200&offset=0")

    @headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
    'content-type' => "application/json",
    'accept' => "application/json"
    }

    uri = URI(url)
    request = Net::HTTP.get_response(uri, @headers)
    body = JSON.parse(request.body)
    chanel_data = ChannelResponseData.find_or_initialize_by(channel: "ebay", api_url: url, api_call: "getOrders")
    if chanel_data.status == "executed"
      chanel_data.save!
    else
      chanel_data.response = body
      if body['errors'].nil?
        chanel_data.status = "panding"
        chanel_data.save!
      else
        chanel_data.status = "error"
        chanel_data.save!
        return
      end
    end
    (1...body['total'].to_i).each_slice(200) do |count|
      offset = count.last
      break unless (offset%200).zero?
      ebay_url = "https://api.ebay.com/sell/fulfillment/v1/order?&limit=200&offset=#{offset}"
      chanel_data = ChannelResponseData.find_or_initialize_by(channel: "ebay", api_url: ebay_url, api_call: "getOrders")
      if ((chanel_data.status == "error") || (chanel_data.status.nil?))
        chanel_data.status = "not available"
      end
      chanel_data.save!
    end
    fetch_panding_orders
  end

  def fetch_panding_orders
    status = 0
    order_urls = ChannelResponseData.all
    order_urls.each do |order_url|
      if ((order_url.api_call == "getOrders") && ((order_url.status == "not available") || (order_url.status == "error") || (order_url.response['orders'].count < 200)))
        uri = URI(order_url.api_url)
        count = 0
        loop do
          count += 1
          request = Net::HTTP.get_response(uri, @headers)
          body = JSON.parse(request.body)
          body_response_record = ChannelResponseData.find_by(api_url: order_url.api_url)
          if body['errors'].nil?
            body_response_record.update(channel: "ebay", response: body, status: "panding")
            status = 1
            break
          else
            body_response_record.update(channel: "ebay", response: body, status: "error")
            status = 0
            if count == 3
              break
            end
          end
        end
      end
    end
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
    flash[:notice] = "Orders call fullfilled successfully"
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
