class ProductMappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[ show update destroy ]
  before_action :refresh_token, only: %i[ index ]

  def index
    if params[:product_mapping] == 'Ebay Sandbox'
      product_invetory_call(@refresh_token)
      ids = ChannelProduct.joins(:product_mapping).pluck(:id)
      @body = ChannelProduct.where("id NOT IN (?)", ids)
      @matching_products = {}
      @body.each do |item|
        matching = Product.find_by("sku LIKE ?", "%#{item.product_data['sku']}%")
        @matching_products[item.id] = matching if matching.present?
      end
    end
    if params[:mapped_status] == 'Mapped'
      @body = ChannelProduct.joins(:product_mapping).includes(:product_mapping)
      @matching_products = {}
      @body.each do |item|
        matching = item.product_mapping.product
        @matching_products[item.id] = matching if matching.present?
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
    if params[:commit] == 'Map'
      product_id = params[:anything]['product_id'] || params['product_id']
      @product_mapping = ProductMapping.create!(channel_product_id: params[:anything]['channel_product_id'], product_id: product_id)
      flash[:notice] = 'Product mapped successfully'
      redirect_to product_mappings_path(product_mapping: 'Ebay Sandbox')
    end
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

      body = JSON.parse(request.body)

      if body["inventoryItems"].present?
        body["inventoryItems"].each do |item|
          ChannelProduct.where(channel_type: 'ebay', product_data: item).first_or_create
        end
      end
      respond_to do |format|
        format.html
      end
    end
end
