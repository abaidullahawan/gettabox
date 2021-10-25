# frozen_string_literal: true

# getting new products and map/create
class ProductMappingsController < ApplicationController
  include NewProduct

  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[show update destroy]
  before_action :refresh_token, only: %i[index xml_file]
  before_action :new_product, :product_load_resources, :load_products, only: %i[index]
  before_action :unmap_product_id, only: %i[unmap_product]
  before_action :map_product_id, only: %i[map_product]

  def index
    maped_products(@body) if params[:q].present? && params[:q][:status_eq] == '1'
    all_order_data if params[:product_mapping] == 'Ebay Production'
    return unless params[:export_csv].present?

    @products = ChannelProduct.all
    export_csv(@products)
  end

  def all_order_data
    CreateChannelProductResponseJob.perform_later
    flash[:notice] = 'Call sent to eBay API'
    redirect_to product_mappings_path
  end

  def maped_products(body)
    @matching_products = {}
    body&.each do |item|
      matching = item.product_mapping&.product
      @matching_products[item.id] = matching if matching.present?
    end
  end

  def show; end

  def new; end

  def xml_file; end

  def edit; end

  def map_product
    if @product_id.present?
      @product_mapping = ProductMapping.create!(channel_product_id: params[:anything]['channel_product_id'],
                                                product_id: @product_id)
      ChannelProduct.find(params[:anything]['channel_product_id']).status_mapped! if @product_mapping.present?
      flash[:notice] = 'Product mapped successfully'
    else
      flash[:alert] = 'Please select product to map'
    end
  end

  def unmap_product
    @product_mapping = ProductMapping.find_by(
      channel_product_id: params[:anything][:channel_product_id],
      product_id: @product_id
    )
    if @product_mapping&.destroy
      ChannelProduct.find(params[:anything][:channel_product_id]).status_unmapped!
      flash[:notice] = 'Product Un-mapped successfully'
    else
      flash[:notice] = 'Product cannot be Un-mapped'
    end
  end

  def attach_photo(product)
    url = URI.parse(product.product_data['ListingDetails']['ViewItemURL'])
    filename = File.basename(url.path)
    begin
      file = URI.parse(url).open
      @product.photo.attach(io: file, filename: filename) if file.present?
      flash[:notice] = 'Product created successfully'
    rescue OpenURI::HTTPError
      flash[:alert] = 'Product created! Cannot upload image'
    end
  end

  def create_product
    cd = ChannelProduct.find(params['channel_product_id'])
    @product = Product.new(product_mapping_params)
    first_or_create_category
    if @product&.save
      ProductMapping.create(channel_product_id: cd.id, product_id: @product.id)
      cd.status_mapped!
      attach_photo(cd)
    else
      flash[:alert] = 'Product cannot be created!'
    end
  end

  def create
    case params[:commit]
    when 'Map'
      map_product
    when 'Un-map'
      unmap_product
    when 'Create'
      create_product
    end
    redirect_to product_mappings_path
  end

  def export_csv(products)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data csv_export(products), filename: "ChannelProducts-#{Date.today}.csv" }
    end
  end

  def update; end

  def destroy; end

  private

  def csv_export(_products)
    attributes = ChannelProduct.column_names.excluding('created_at', 'updated_at')
    CSV.generate(headers: true) do |csv|
      csv << attributes
      ChannelProduct.all.each do |products|
        csv << attributes.map { |attr| products.send(attr) }
      end
    end
  end

  def product_mapping_params
    params
      .require(:product)
      .permit(:sku, :title, :photo, :total_stock, :fake_stock, :pending_orders, :allocated_orders,
              :available_stock, :length, :width, :height, :weight, :pack_quantity, :cost_price, :gst, :vat,
              :hst, :pst, :qst, :minimum, :maximum, :optimal, :category_id, :product_type, :season_id, :description,
              barcodes_attributes: %i[id title _destroy],
              product_suppliers_attributes:
              %i[id system_user_id product_cost product_sku product_vat _destroy],
              multipack_products_attributes:
              %i[id product_id child_id quantity _destroy])
  end

  # def product_invetory_call(refresh_token)
  #   require 'uri'
  #   require 'net/http'

  #   url = 'https://api.sandbox.ebay.com/sell/inventory/v1/inventory_item?offset=0'
  #   headers = { 'authorization' => "Bearer <#{refresh_token.access_token}>",
  #               'accept-language' => 'en-US' }
  #   uri = URI(url)
  #   request = Net::HTTP.get_response(uri, headers)

  #   body = JSON.parse(request.body)

  #   if body['inventoryItems'].present?
  #     body['inventoryItems'].each do |item|
  #       ChannelProduct.where(channel_type: 'ebay', product_data: item).first_or_create
  #     end
  #   end
  #   respond_to do |format|
  #     format.html
  #   end
  # end

  def load_products
    @q = ChannelProduct.ransack(params[:q])
    @body = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    fetch_products
  end

  def fetch_products
    @matching_products = {}
    @body&.each do |item|
      matching = item.product_mapping&.product || Product.find_by('sku LIKE ?', "%#{item.item_sku}%")
      @matching_products[item.id] = matching if matching.present?
    end
  end

  def unmap_product_id
    @product_id = params[:anything][:mapped_product_id] || params[:mapped_product_id]
  end

  def map_product_id
    product_id = params[:anything][:product_id].presence || params[:anything][:mapped_product_id]
    @product_id = Product.find_by(title: product_id).id if product_id.to_i.to_s != product_id
  end
end
