# frozen_string_literal: true

# getting new products and map/create
class ProductMappingsController < ApplicationController
  include NewProduct
  include AutoAssignRule

  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[show update destroy]
  before_action :refresh_token, :refresh_token_amazon, only: %i[index xml_file]
  before_action :new_product, :product_load_resources, :load_products, :export_csv, only: %i[index]
  before_action :fetch_product_id, only: %i[create]
  skip_before_action :verify_authenticity_token

  def index
    @product_exports = ExportMapping.where(table_name: 'ChannelProduct')
    amazon_request if params[:commit].eql? 'Amazon Request'
    maped_products(@body) if params[:q].present? && (params[:q][:status_eq].eql? '1')
    all_product_data if params[:all_product_data].present?
  end

  def all_product_data
    if params[:amazon]
      # job_data = AmazonProductJob.perform_later
      JobStatus.create(name: 'AmazonProductJob', status: 'inqueue', perform_in: 300)
      flash[:notice] = 'Amazon product job created!'
    else
      # job_data = CreateChannelProductResponseJob.perform_later
      JobStatus.create(name: 'CreateChannelProductResponseJob', status: 'inqueue', perform_in: 300)
      flash[:notice] = 'Call sent to eBay API'
    end
    redirect_to product_mappings_path
  end

  def maped_products(body)
    @matching_products = {}
    body&.each do |item|
      matching = item.product_mapping&.product
      @matching_products[item.id] = matching if matching.present?
    end
  end

  def version
    @channel_product = ChannelProduct.find_by(id: params[:id])
    @mappings = ProductMapping.where(channel_product_id: @channel_product.id)
    @versions = if @mappings.present?
                  @channel_product&.product_mapping&.versions
                else
                  Version.find_by(item_type: 'ChannelProduct',
                                  item_id: @channel_product.id.to_s)
                end
    @product = Product.find(@versions.object_changes) if @mappings.blank? && @versions.present?
  end

  def show; end

  def new; end

  def xml_file; end

  def edit; end

  def map_product
    @product_id = params[:anything][:searched_product_id].presence || params[:anything][:mapped_product_id]
    @product = Product.find_by(id: @product_id)
    @channel_product = ChannelProduct.find_by(id: params[:anything]['channel_product_id'])
    @product_id = @product&.id if @product_id.to_i.to_s != @product_id
    if @product_id.present?
      @product_mapping = ProductMapping.create!(channel_product_id: @channel_product.id,
                                                product_id: @product_id)

      @channel_product.status_mapped! if @product_mapping.present?
      if @product.product_type == 'multiple'
        update_multi_pack_logs(@channel_product, @product)
      else
        @product.update(change_log: "Product Mapped, #{@product.sku}, #{@channel_product.item_sku}, Mapped, #{@channel_product.listing_id}, #{@product.inventory_balance}, #{current_user&.personal_detail&.full_name}")
        update_order_stage(@channel_product, @product)
      end
      allocations
      flash[:notice] = 'Product mapped successfully'
    else
      flash[:alert] = 'Please select product to map'
    end
  end

  def unmap_product
    @product = Product.find_by(id: params[:anything][:mapped_product_id] || params[:mapped_product_id])
    @channel_product = ChannelProduct.find(params[:anything][:channel_product_id])
    @product_id = @product.id
    channel_product_id = @channel_product.id
    @product_mapping = ProductMapping.find_by(
      channel_product_id: @channel_product.id,
      product_id: @product_id
    )
    if @product.product_type_single?
      @product.update(
        change_log: "Product UnMapped, #{@product.sku}, #{@channel_product.item_sku}, Product UnMapped,
        #{@channel_product.listing_id}, #{@product.inventory_balance}, #{current_user&.personal_detail&.full_name}"
      )
    else
      multipacks = @product.multipack_products
      multipacks.each do |multipack|
        multipack.child.update(
          change_log: "Product UnMapped, #{multipack.child.sku}, #{@channel_product.item_sku}, Product UnMapped,
          #{@channel_product.listing_id}, #{multipack.child.inventory_balance}, #{current_user&.personal_detail&.full_name}"
        )
      end
    end
    orders = unmapped_orders(channel_product_id)
    orders&.each do |order|
      allocate_or_unallocate(order.channel_order_items)
    end
    if @product_mapping&.destroy && @channel_product.status_unmapped!
      channel_order_ids = ChannelOrderItem.where(channel_product_id: channel_product_id).pluck(:channel_order_id)
      ChannelOrder.where(id: channel_order_ids).update_all(stage: 'unmapped_product_sku')
      flash[:notice] = 'Product Un-mapped successfully'
    else
      flash[:notice] = 'Product cannot be Un-mapped'
    end
  end

  def attach_photo(product)
    url = product.product_data['PictureDetails']['GalleryURL']
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
      if params['product']['product_type'] == 'multiple'
        update_multi_pack_logs(cd, @product)
      else
        @product.update(change_log: "Product Mapped, #{@product.sku}, #{cd.item_sku}, Mapped, #{cd.listing_id}, #{@product.inventory_balance}, #{current_user&.personal_detail&.full_name}")
        update_order_stage(cd, @product)
      end
      attach_photo(cd) unless @product.photo.attached? || cd.product_data['PictureDetails'].nil?
    else
      flash[:alert] = @product.errors.full_messages
    end
  end

  def create
    case params[:commit]
    when 'Map'
      map_product
    when nil
      map_product
    when 'Un-map'
      unmap_product
    when 'Create'
      create_product
    end
    redirect_to request.referrer
    # if request.referrer.include? 'order_dispatches'
    #   redirect_to order_dispatches_path(order_filter: 'unprocessed')
    # else
    #   redirect_to product_mappings_path
    # end
  end

  def export_csv
    return unless params[:export_csv]

    export_products = params[:selected] ? @products.where(selected: true) : @products
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        export_products.each do |product|
          csv << attributes.map { |attr| product.send(attr) }
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "ChannelProducts-#{Date.today}.csv" }
      end
    else
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data csv_export(export_products), filename: "ChannelProducts-#{Date.today}.csv" }
      end
    end
  end

  def update; end

  def destroy; end

  def import
    file = params[:file]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(file).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
      convert = ImportMapping.where(sub_type: params[:mapping_type]).last.mapping_data.invert
      csv = CSV.parse(csv_text, headers: true, skip_blanks: true, header_converters: ->(name) { convert[name] })
      csv_headers_check(csv)
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    redirect_to product_mappings_path
  end

  def csv_headers_check(csv)
    is_valid = (csv.headers.compact | ChannelProduct.column_names).sort == ChannelProduct.column_names.sort
    if is_valid
      csv.each do |row|
        row = row.to_hash
        row.delete(nil)
        channel_product = ChannelProduct.new
        channel_product.update(row)
      end
    else
      flash[:alert] = 'File not matched! Please change file'
    end
  end

  def import_product_file
    return unless params[:channel_product][:file].present?

    file = params[:channel_product][:file]
    file_type = file.present? ? file.path.split('.').last.to_s.downcase : ''
    if file.present? && (file_type.include? 'csv') || (file_type.include? 'xlsx')
      spreadsheet = open_spreadsheet(file)
      @header = spreadsheet.headers
      @data = []
      @import_mapping = ImportMapping.new
      @table_names = %w['Order Product']
      @db_names = ChannelProduct.column_names
      redirect_to new_import_mapping_path(db_columns: @db_names, header: @header, import_mapping: @import_mapping)
    else
      flash[:alert] = 'Try again file not match'
      redirect_to import_mappings_path
    end
  end

  private

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv' then CSV.parse(File.read(file.path).force_encoding('ISO-8859-1').encode('utf-8', replace: nil),
                               headers: true)
    when '.xls' then  Roo::Excel.new(file.path, packed: nil, file_warning: :ignore)
    when '.xlsx' then Roo::Excelx.new(file.path, packed: nil, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def csv_export(product)
    attributes = ChannelProduct.column_names.excluding('created_at', 'updated_at', 'product_data', 'product_range_id', 'range_sku', 'assign_rule_id', 'selected', 'status', 'error_message').including('product_title', 'product_sku', 'product_quantity', 'status')
    CSV.generate(headers: true) do |csv|
      csv << attributes
      product.each do |channel_product|
        row = channel_product.attributes.values_at(*attributes)
        # value = add_avaialable_stock(channel_product) if channel_product.status_mapped?
        # row[-1] = value if value.present?
        quantity = add_product_mapped_quantity(channel_product) if channel_product.status_mapped?
        row[-2] = quantity if quantity.present?
        sku = add_product_mapped_sku(channel_product) if channel_product.status_mapped?
        row[-3] = sku if sku.present?
        title = add_product_mapped_title(channel_product) if channel_product.status_mapped?
        row[-4] = title if title.present?
        csv << row
      end
    end
  end

  # def add_avaialable_stock(channel_product)
  #   product = channel_product.product_mapping.product
  #   return multipack_products_stock(product) if product.product_type_multiple?

  #   calculate_available_stock(product)
  # end

  def add_product_mapped_quantity(channel_product)
    product = channel_product.product_mapping.product
    product.total_stock
  end

  def add_product_mapped_sku(channel_product)
    product = channel_product.product_mapping.product
    product.sku
  end

  def add_product_mapped_title(channel_product)
    product = channel_product.product_mapping.product
    product.title
  end

  # def multipack_products_stock(product)
  #   stocks = []
  #   product.multipack_products.each do |multipack|
  #     single_product = multipack.child
  #     stocks << calculate_available_stock(single_product) unless single_product.nil?
  #   end
  #   stocks.min
  # end

  # def calculate_available_stock(product)
  #   pack_quantity = product.pack_quantity.to_i
  #   quantity = pack_quantity.nil? || pack_quantity&.zero? ? 1 : pack_quantity
  #   stock = ((product.total_stock.to_i + product.fake_stock.to_i - 10) / 2) / quantity
  #   if stock > 2
  #     stock = 2
  #   elsif stock.negative?
  #     stock = 0
  #   end
  #   stock
  # end

  def product_mapping_params
    params
      .require(:product)
      .permit(:sku, :title, :photo, :total_stock, :fake_stock, :pending_orders, :allocated,
              :available_stock, :length, :width, :height, :weight, :pack_quantity, :cost_price, :gst, :vat,
              :minimum, :maximum, :optimal, :category_id, :product_type, :season_id, :description,
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
    @products = @q.result(distinct: true).order(created_at: :desc)
    @body = @products.page(params[:page]).per(params[:limit])

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

  def update_order_stage(channel_product, product)
    ids = ChannelOrder.joins(:channel_order_items).includes(:channel_order_items)
                      .where('channel_order_items.channel_product_id': channel_product.id).pluck(:id)
    orders = ChannelOrder.where(id: ids, stage: %w[unmapped_product_sku unable_to_find_sku])
    concern_recalculate_rule(orders)
    orders.each do |order|
      next if order.channel_order_items.map { |i| i.channel_product.status }.any?('unmapped')

      order.update(stage: 'ready_to_dispatch')
      channel_type = order.channel_type
      unshipped = product.unshipped + order.channel_order_items.pluck(:ordered).sum if product.unshipped.present?
      inventory_balance = product.total_stock.to_i - unshipped.to_i
      product.update(change_log: " Order Paid, #{channel_product.item_sku}, #{order.order_id}, Order Paid, #{channel_product.listing_id}, #{unshipped}, #{inventory_balance}, #{channel_type} ", unshipped: unshipped, inventory_balance: inventory_balance, unshipped_orders: product.unshipped_orders.to_i + 1)
    end
  end

  def update_multi_pack_logs(channel_product, product)
    orders = ChannelOrder.joins(:channel_order_items).includes(:channel_order_items)
                         .where('channel_order_items.channel_product_id': channel_product.id)
    product.multipack_products.each do |multi_pack_log|
      multi_pack_log.child.update(change_log: "Product Mapped, #{multi_pack_log.child.sku}, #{channel_product.item_sku}, Mapped, #{channel_product.listing_id}, #{multi_pack_log.child.inventory_balance}, #{current_user&.personal_detail&.full_name}")
    end
    concern_recalculate_rule(orders)
    orders.each do |order|
      channel_type = order.channel_type
      order.update(stage: 'ready_to_dispatch')
      product.multipack_products.each do |multi_pack_log|
        unshipped_log = multi_pack_log.quantity.to_i * order.channel_order_items.pluck(:ordered).sum
        unshipped = multi_pack_log.child.unshipped.to_i + unshipped_log.to_i
        inventory_balance = multi_pack_log.child.total_stock.to_i - unshipped.to_i
        multi_pack_log.child.update(change_log: " Order Paid, #{channel_product.item_sku}, #{order.order_id}, Order Paid, #{channel_product.listing_id}, #{unshipped}, #{inventory_balance}, #{channel_type} ", unshipped: unshipped, inventory_balance: inventory_balance, unshipped_orders: multi_pack_log.child&.unshipped_orders.to_i + 1)
      end
    end
  end

  def allocations
    order_items = ChannelOrder.find_by(id: params['anything']['channel_order_id'])&.channel_order_items
    return unless order_items.present?

    order_items.each do |item|
      allocate_item(item)
    end
  end

  def allocate_item(order_item)
    product = order_item.channel_product.product_mapping.product
    return multipack_allocation(order_item, product) if product&.product_type.eql? 'multiple'

    return unless product&.available_stock.to_i >= order_item.ordered

    product.update(available_stock: product.available_stock.to_f - order_item.ordered,
                   allocated: product.allocated.to_f + order_item.ordered, allocated_orders: product.allocated_orders.to_i + 1)
    # change_log: "#{order_item.channel_order.channel_type} API, #{order_item.channel_order.id}, #{order_item.channel_order.order_id}, Allocated, #{order_item.channel_product.listing_id}")
    order_item.update(allocated: true)
  end

  def multipack_allocation(order_item, product)
    available = product.multipack_products.map { |m| m.child.available_stock.to_i }
    required = product.multipack_products.map { |m| m.quantity.to_i * order_item.ordered }
    check = available.zip(required).all? { |a, b| a >= b }
    return unless check

    product.multipack_products.each do |multipack|
      child = multipack.child
      quantity = multipack.quantity
      ordered = (order_item.ordered * quantity)
      child.update(available_stock: child.available_stock.to_f - ordered,
                   allocated: child.allocated.to_f + ordered, allocated_orders: child.allocated_orders.to_i + 1)
      # change_log: "#{order_item.channel_order.channel_type} API, #{order_item.channel_order.id}, #{order_item.channel_order.order_id}, Allocated, #{order_item.channel_product.listing_id}")
    end
    order_item.update(allocated: true)
  end

  def unmapped_orders(channel_product_id)
    stages = %w[ready_to_dispatch ready_to_print]
    ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: :product]])
                .includes(channel_order_items: [channel_product: [product_mapping: :product]])
                .where(stage: stages, "channel_product.id": channel_product_id)
  end

  def allocate_or_unallocate(channel_items)
    channel_items.each do |item|
      product = item.channel_product.product_mapping.product
      if product.present?
        next multipack_product(item, product) unless product.product_type.eql? 'single'

        inventory_balance = product.inventory_balance.to_f + item.ordered
        update_available_stock(item, product, inventory_balance, item.ordered)
      end
    end
  end

  def multipack_product(item, product)
    available = product.multipack_products.map { |m| m.child.available_stock.to_i }
    required = product.multipack_products.map { |m| m.quantity.to_i * item.ordered }
    check = available.zip(required).all? { |a, b| a >= b }
    return unless check

    multipack_allocation_unmapped(item, product)
  end

  def multipack_allocation_unmapped(item, product)
    product.multipack_products.each do |multipack|
      quantity = multipack.quantity
      child = multipack.child
      inventory_balance = child.inventory_balance.to_f + (item.ordered * quantity)
      update_available_stock(item, child, inventory_balance, (item.ordered * quantity))
    end
  end

  def update_available_stock(item, product, inventory_balance, ordered)
    unshipped = product.unshipped - ordered if product.unshipped.present?
    product.update(
      change_log: "Product Unmapped, #{item.channel_product.item_sku}, #{item.channel_order.order_id}, Unmapped,
      #{item.channel_product.listing_id}, #{unshipped}, #{inventory_balance}, #{current_user&.personal_detail&.full_name} ",
      unshipped: unshipped, unshipped_orders: product.unshipped_orders.to_i - 1
    )
    if item.allocated
      product.update(allocated: product.allocated.to_i - ordered, allocated_orders: product.allocated_orders.to_i - 1)
    else
      product.update(unallocated: product.unallocated.to_i - ordered)
    end
    item.update(allocated: false)
  end
end
