class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  # before_action :refresh_token, only: %i[ index ]

  def index
  end

  def show
  end

  def create
  end

  private
    def order_mapping_params
    end

    def order_invetory_call(refresh_token)
      require 'uri'
      require 'net/http'
      url = ('https://api.sandbox.ebay.com/sell/inventory/v1/inventory_item?offset=0')
      params = { :limit => 10, :page => 3 }
      headers = { 'authorization' => "Bearer <#{refresh_token.access_token}>",
                  'accept-language' => 'en-US'}
      uri = URI(url)
      request = Net::HTTP.get_response(uri, headers)

      body = JSON.parse(request.body)

      if body["inventoryItems"].present?
        body["inventoryItems"].each do |item|
          ChannelProduct.where(channel_type: 'ebay', order_data: item).first_or_create
        end
      end
      respond_to do |format|
        format.html
      end
    end
end
