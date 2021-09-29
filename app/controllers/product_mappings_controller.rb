class ProductMappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[ show update destroy ]
  before_action :refresh_token, only: %i[ index ]

  def index
    if params[:product_mapping] == 'Ebay Sandbox' || params[:mapped_status] == 'Unmapped'
      product_invetory_call(@refresh_token) if @refresh_token.present?
      ids = ChannelProduct.joins(:product_mapping).pluck(:id)
      ids.any? ? @body = ChannelProduct.where("id NOT IN (?)", ids) : @body = ChannelProduct.all
      @matching_products = {}
      @body&.each do |item|
        matching = Product.find_by("sku LIKE ?", "%#{item.product_data['sku']}%")
        @matching_products[item.id] = matching if matching.present?
      end
    end
    if params[:mapped_status] == 'Mapped'
      @body = ChannelProduct.joins(:product_mapping).includes(:product_mapping)
      @matching_products = {}
      @body&.each do |item|
        matching = item.product_mapping.product
        @matching_products[item.id] = matching if matching.present?
      end
    end
    new_product
  end

  def new_product
    @product = Product.new
    @product.barcodes.build
    @product.product_suppliers.build
    @product.multipack_products.build
    @single_products = Product.where(product_type: 'single').map{|v| v.serializable_hash(only: [:id, :title]) }
    @system_users = SystemUser.all.map{|v| v.serializable_hash(only: [:id, :name]) }
    @categories = Category.all.map{|v| v.serializable_hash(only: [:id, :title]) }
    @seasons = Season.all.map{|v| v.serializable_hash(only: [:id, :name]) }
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
      if product_id.present?
        @product_mapping = ProductMapping.create!(channel_product_id: params[:anything]['channel_product_id'], product_id: product_id)
        flash[:notice] = 'Product mapped successfully'
        redirect_to product_mappings_path(product_mapping: 'Ebay Sandbox')
      else
        flash[:alert] = 'Please select product to map'
        redirect_to product_mappings_path(product_mapping: 'Ebay Sandbox')
      end
    end
    if params[:commit] == 'Un-map'
      product_id = params[:anything]['product_id'] || params['product_id']
      @product_mapping = ProductMapping.find_by(channel_product_id: params[:anything]['channel_product_id'], product_id: product_id)
      @product_mapping&.destroy
      flash[:notice] = 'Product Un-mapped successfully'
      redirect_to product_mappings_path(mapped_status: 'Mapped')
    end
    if params[:commit] == 'Create'
      cd = ChannelProduct.find(params['channel_product_id'])
      begin
        @product = Product.new(product_mapping_params)
      rescue NoMethodError
        flash[:alert] = 'Product params not matched'
        # redirect_to product_mappings_path(product_mapping: 'Ebay Sandbox')
      end
      if @product&.save
        ProductMapping.create(channel_product_id: cd.id, product_id: @product.id)
        url = URI.parse(cd.product_data['product']['imageUrls'].first)
        filename = File.basename(url.path)
        begin
          file = URI.open(url)
          @product.photo.attach(io: file, filename: filename) if file.present?
          flash[:notice] = 'Product created successfully'
          redirect_to product_mappings_path(product_mapping: 'Ebay Sandbox')
        rescue OpenURI::HTTPError => e
          flash[:alert] = 'Product created! Cannot upload image'
          redirect_to product_mappings_path(product_mapping: 'Ebay Sandbox')
        end
      else
        flash[:alert] = 'Product cannot be created!'
        redirect_to product_mappings_path(product_mapping: 'Ebay Sandbox')
      end
    end
  end

  def update
  end

  def destroy
  end

  private
    def product_mapping_params
      params.
      require(:product).
      permit( :sku,
              :title,
              :photo,
              :total_stock,
              :fake_stock,
              :pending_orders,
              :allocated_orders,
              :available_stock,
              :length,
              :width,
              :height,
              :weight,
              :pack_quantity,
              :cost_price,
              :gst,
              :vat,
              :hst,
              :pst,
              :qst,
              :minimum,
              :maximum,
              :optimal,
              :category_id,
              :product_type,
              :season_id,
              :description,
              barcodes_attributes:
              [ :id,
                :title,
                :_destroy
              ],
              product_suppliers_attributes:
              [ :id,
                :system_user_id,
                :product_cost,
                :product_sku,
                :product_vat,
                :_destroy
              ],
              multipack_products_attributes:
              [ :id,
                :product_id,
                :child_id,
                :quantity,
                :_destroy
              ]
      )
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
