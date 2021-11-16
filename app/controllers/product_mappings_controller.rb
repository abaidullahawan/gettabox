# frozen_string_literal: true

# getting new products and map/create
class ProductMappingsController < ApplicationController
  include NewProduct

  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[show update destroy]
  before_action :refresh_token, :refresh_token_amazon, only: %i[index xml_file]
  before_action :new_product, :product_load_resources, :load_products, only: %i[index]
  before_action :fetch_product_id, only: %i[create]
  skip_before_action :verify_authenticity_token

  def index
    amazon_request if params[:commit].eql? 'Amazon Request'
    maped_products(@body) if params[:q].present? && (params[:q][:status_eq].eql? '1')
    all_order_data if params[:all_product_data].present?
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
    @product_id = params[:anything][:product_id].presence || params[:anything][:mapped_product_id]
    @product_id = Product.find_by(title: @product_id)&.id if @product_id.to_i.to_s != @product_id
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
    @product_id = params[:anything][:mapped_product_id] || params[:mapped_product_id]
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
    url = product.product_data["PictureDetails"]["GalleryURL"]
    filename = File.basename(url.pathmap)
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
      attach_photo(cd) unless @product.photo.attached?
    else
      flash[:alert] = @product.errors.full_messages
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
    if request.referrer == "http://localhost:3000/order_dispatches" || request.referrer == "https://portal.channeldispatch.co.uk/order_dispatches"
      redirect_to order_dispatches_path
    else
      redirect_to product_mappings_path
    end
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
    if params[:product_mapping].eql? 'Amazon Products'
      @q = ChannelProduct.where(channel_type: 'amazon').ransack(params[:q])
    elsif params[:product_mapping].eql? 'Ebay Products'
      @q = ChannelProduct.where(channel_type: 'ebay').ransack(params[:q])
    elsif params[:issue_product].present?
      @q = ChannelProduct.where(item_sku: nil).ransack(params[:q])
    else
      @q = ChannelProduct.ransack(params[:q])
    end
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

  def fetch_product_id
    mapped_product_id = params['anything']['mapped_product_id'] if params['anything'].present?
    case params[:commit]
    when 'Map'
      @product_id = mapped_product_id || params[:mapped_product_id]
    when 'Un-map'
      @product_id = params[:anything][:product_id].presence || mapped_product_id
      @product_id = Product.find_by(title: @product_id).id if @product_id.to_i.to_s != @product_id
    end
  end

  def amazon_request
    user_code = session[:user_code]
    device_code = session[:device_code]
    remainaing_time = session[:expires_in] < DateTime.now
    return amazon_refresh_token(user_code, device_code) if user_code.present? && device_code.present? && remainaing_time

    amazon_user_code
  rescue StandardError
    flash[:alert] = 'Please contact your administration for process'
  end

  def store_session(body)
    session[:user_code] = body['user_code']
    session[:device_code] = body['device_code']
    session[:verification_uri] = body['verification_uri']
    session[:expires_in] = DateTime.now + body['expires_in'].to_i.seconds

    flash[:notice] = "Please verify with this code { #{user_code} in #{body['verification_uri']} } "
  end

  def amazon_user_code
    result = AmazonDeviceCodeService.device_code_api
    return store_session(result[:body]) if result[:status]

    flash[:alert] = (result[:error]).to_s
  end

  def amazon_refresh_token(user_code, device_code)
    result = AmazonDeviceCodeService.refresh_token_api(user_code, device_code)
    return create_refresh_token(result[:body]) if result[:status]

    flash[:alert] = (result[:error]).to_s
  end

  def create_refresh_token(body)
    refresh_token = RefreshToken.find_or_initialize_by(channel: 'amazon')
    refresh_token.update(
      refresh_token: body['refresh_token'],
      access_token: body['access_token'],
      access_token_expiry: DateTime.now + body['expires_in'].to_i.seconds
    )
    flash[:notice] = 'Refresh Token and Access Token created successfully'
  end
end
