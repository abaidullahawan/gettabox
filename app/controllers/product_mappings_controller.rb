class ProductMappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[ show update destroy ]

  def index
    if params[:product_mapping] == 'Ebay Sandbox'
      require 'uri'
      require 'net/http'

      url = ('https://api.sandbox.ebay.com/sell/inventory/v1/inventory_item?offset=0')
      params = { :limit => 10, :page => 3 }
      headers = { 'authorization' => 'Bearer <v^1.1#i^1#f^0#p^3#I^3#r^0#t^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>',
                  'accept-language' => 'en-US'}
      # uri.query = URI.encode_www_form(params)
      # res = Net::HTTP.get_response(uri)
      # puts res.body if res.is_a?(Net::HTTPSuccess)
      uri = URI(url)
      request = Net::HTTP.get_response(uri, headers)

      # request.body = request # SOME JSON DATA e.g {msg: 'Why'}.to_json

      # response = http.request(request)

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
end
