class ProductMappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[ show update destroy ]
  before_action :refresh_token, only: %i[ index ]

  def index
    if params[:product_mapping] == 'Ebay Sandbox'
      product_invetory_call(@refresh_token)
    end
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
  end

  private
    def product_mapping_params
    end

    def product_invetory_call(refresh_token)
      require 'uri'
      require 'net/http'
      url = ('https://api.sandbox.ebay.com/sell/inventory/v1/inventory_item?offset=0')
      params = { :limit => 10, :page => 3 }
      headers = { 'authorization' => "Bearer <#{refresh_token.access_token}>",
                  'accept-language' => 'en-US'}
      uri = URI(url)
      request = Net::HTTP.get_response(uri, headers)

      @body = JSON.parse(request.body) # e.g {answer: 'because it was there'}

      if @body["inventoryItems"].present?
        @body["inventoryItems"].each do |item|
          matching = Product.find_by("sku LIKE ?", "%#{item['sku']}%")
          matching.present? ? item['matching'] = matching : item['matching'] = nil
        end
      end
      respond_to do |format|
        format.html
      end
    end
end
