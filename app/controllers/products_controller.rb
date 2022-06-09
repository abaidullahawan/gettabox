# frozen_string_literal: true

# Products Crud
class ProductsController < ApplicationController
  include NewProduct
  include ImportExport

  before_action :authenticate_user!
  before_action :find_product, only: %i[edit update show destroy]
  before_action :product_load_resources, only: %i[index new edit show create update]
  before_action :fetch_field_names, only: %i[new create show index]
  before_action :load_show, only: %i[show]
  # before_action :attributes_for_filter, only: [:index]
  before_action :new_product, :ransack_products, only: %i[index]
  before_action :build_product, only: %i[create]
  skip_before_action :verify_authenticity_token, only: %i[create update]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    export_csv(@q.result) if params[:export_csv].present?
    respond_to do |format|
      format.html
      format.csv
      format.pdf do
        render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'products/index.pdf.erb'
      end
    end
    @q.result.update_all(fake_stock: 0) if params[:fake_stock].present?
  end

  def new; end

  def create
    first_or_create_category
    if @product.save
      flash[:notice] = 'Created successfully.'
      redirect_to product_path(@product)
    else
      ransack_products
      flash.now[:alert] = 'Product cannot be created!'
      render 'index'
    end
  end

  def edit; end

  def update_extra_fields
    @product.extra_field_value.update(field_value: params[:product][:extra_field_value_attributes])
    flash[:notice] = 'Updated successfully.'
    redirect_to product_path(@product)
  end

  def update
    if product_params[:total_stock].present?
      difference = product_params[:total_stock].to_i - @product.total_stock.to_i
      stock = @product.manual_edit_stock.to_i
      stock += difference
    end
    if params[:product][:extra_field_value_attributes].present?
      update_extra_fields
    elsif @product.update(product_params)
      update_log(stock) if product_params[:total_stock].present?
      flash[:notice] = 'Updated successfully.'
      if product_params[:product_forecastings_attributes].present?
        buffer_rule(@product)
      end
      redirect_to product_path(@product)
    else
      load_show
      render 'show'
    end
  end

  def buffer_rule(product)
    channel_forecastings = product.channel_forecastings
    sigle_listings = ChannelProduct.joins(product_mapping: :product).where('product_mappings.product_id': product.id)
    multi_listings = ChannelProduct.joins(product_mapping: [product: [multipack_products: :child]]).where('child.id': product.id)
    sigle_listings.update_all(buffer_quantity: nil)
    multi_listings.update_all(buffer_quantity: nil)
    listings = sigle_listings + multi_listings
    channel_forecastings.each do |channel_forecasting|
      listings.each do |listing|
        if listing.channel_type == channel_forecasting.filter_by
          if channel_forecasting.action == 'safe_stock_by'
            channel_quantity = listing.item_quantity.to_i - channel_forecasting.type_number.to_i
            channel_quantity = 0 if channel_quantity.negative?
            listing.update(buffer_quantity: -channel_forecasting.type_number, item_quantity: channel_quantity, item_quantity_changed: true)
          else
            if listing.channel_type_ebay?
              channel_quantity = listing.item_quantity.to_i + channel_forecasting.type_number.to_i
              selling_quantity = Selling&.last&.quantity.to_i
              channel_quantity = selling_quantity if channel_quantity > selling_quantity
              listing.update(buffer_quantity: channel_forecasting.type_number, item_quantity: channel_quantity, item_quantity_changed: true)
            else
              listing.update(buffer_quantity: channel_forecasting.type_number, item_quantity: listing.item_quantity.to_i + channel_forecasting.type_number.to_i, item_quantity_changed: true)
            end
          end
          # next unless Rails.env.production?

          # if listing.channel_type_ebay? && (listing.listing_type.eql? 'variation')
          #   job_data = UpdateEbayVariationProductJob.perform_later(listing_id: listing.listing_id, sku: listing.item_sku, quantity: listing.item_quantity)
          #   JobStatus.create(job_id: job_data.job_id, name: 'UpdateEbayVariationProductJob', status: 'Queued',
          #                    arguments: { listing_id: listing.listing_id, sku: listing.item_sku, quantity: listing.item_quantity })
          # elsif listing.channel_type_ebay? && (listing.listing_type.eql? 'single')
          #   job_data = UpdateEbaySingleProductJob.perform_later(listing_id: listing.listing_id, quantity: listing.item_quantity)
          #   JobStatus.create(job_id: job_data.job_id, name: 'UpdateEbaySingleProductJob', status: 'Queued',
          #                    arguments: { listing_id: listing.listing_id, quantity: listing.item_quantity })
          # end
        end
      end
    end
  end

  def export_logs
    product = Product.find_by(id: params[:product_id])
    versions = product&.versions&.reorder('versions.created_at DESC')
    headers = ['Date', 'Time', 'Action', 'System ID', 'Channel ID', 'Channel Item ID', 'Changed', 'Result', 'User']
    csv_data = CSV.generate(headers: true) do |csv|
      csv << headers
      versions.each do |version|
        if version.changeset.include? 'change_log'
          csv << [
            version.created_at&.strftime('%m/%d/%Y'),
            version.created_at&.strftime('%I:%M %p'),
            version.changeset.try(:[], 'change_log')&.at(1).try(:split, ',')&.at(3),
            (version.changeset.try(:[], 'change_log')&.at(1).include? 'Purchase Order Recieved') ? 'PO%.4d' % version.changeset.try(:[], 'change_log')&.at(1).try(:split, ',')&.at(1).to_i : version.changeset.try(:[], 'change_log')&.at(1).try(:split, ',')&.at(1),
            version.changeset.try(:[],'change_log')&.at(1).try(:split, ',')&.at(2),
            version.changeset.try(:[],'change_log')&.at(1).try(:split, ',')&.at(4),
            (version.changeset&.include? 'unshipped') ? version.changeset.try(:[],'unshipped')&.at(0).to_i - version.changeset.try(:[],'unshipped')&.at(1).to_i : (version.changeset.try(:[],'change_log')&.at(1)&.include? 'Product Mapped') ? 0 : (version.changeset.try(:[],'change_log')&.at(1).split(',')&.include? 'Manual Edit') ? version.changeset.try(:[],'manual_edit_stock')&.at(1).to_i - version.changeset.try(:[],'manual_edit_stock')&.at(0).to_i : (version.changeset.try(:[],'change_log')&.at(1).split(',')&.include? 'Purchase Order') ? version.changeset.try(:[],'change_log')&.at(1).try(:split, ",")&.at(-1).to_i : version.changeset.try(:[],'change_log')&.at(1).try(:split, ",")&.at(2),
            (version.changeset&.include? 'inventory_balance') ? version.changeset.try(:[],'inventory_balance')&.at(1).to_i : version.changeset.try(:[],'change_log')&.at(1).try(:split, ",")&.at(5).to_i,
            version.whodunnit.present? ? User.find_by(id: version.whodunnit)&.personal_detail&.full_name : 'Developer'
          ]
        end
      end
    end
    send_data csv_data, filename: "product-logs-#{Date.today}.csv", disposition: :attachment
  end

  def show
    @forecasting = ChannelForecasting.all
    @product.product_forecastings
  end

  def destroy
    if @product.product_mappings.present?
      flash[:alert] = 'Cannot archive mapped product'
    else
      @product.destroy
      flash[:notice] = 'Product archive successful'
    end
    redirect_to request.referrer
  end

  def export_csv(products)
    products = products.where(selected: true) if params[:selected]
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        products.each do |product|
          csv << attributes.map { |attr| product.send(attr) }
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "products-#{Date.today}.csv" }
      end
    else
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data products.to_csv, filename: "products-#{Date.today}.csv" }
      end
    end
  end

  def import
    if @csv.present?
      @csv.delete('id')
      @csv.delete('created_at')
      @csv.delete('updated_at')
      csv_create_records(@csv)
      flash[:notice] = 'File Upload Successful!'
    end
    redirect_to products_path
  end

  def bulk_method
    redirect_to products_path
  end

  def archive
    @q = Product.only_deleted.ransack(params[:q])
    @products = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_products_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && Product.only_deleted.find(params[:object_id]).really_destroy!
                       'Product deleted successfully'
                     else
                       'Product cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_products_path
  end

  def search_products_by_title
    @searched_products = Product.ransack('sku_or_title_cont': params[:search_value].downcase.to_s, 'id_not_in': params[:product_selected])
                                .result.limit(20).pluck(:id, :sku, :title)
    respond_to do |format|
      format.json  { render json: @searched_products }
    end
  end

  def search_products_by_sku
    @searched_product_by_sku = Product.ransack('sku_cont': params[:search_value].downcase.to_s)
                                      .result.limit(20).pluck(:id, :sku)
    respond_to do |format|
      format.json  { render json: @searched_product_by_sku }
    end
  end

  def search_category
    @searched_category = Category.ransack('title_cont': params[:search_value].downcase.to_s)
                                 .result.limit(20).pluck(:id, :title)
    respond_to do |format|
      format.json  { render json: @searched_category }
    end
  end

  def import_product_file
    return unless params[:product][:file].present?

    table_name = params[:product][:table_name]
    file = params[:product][:file]
    file_type = file.present? ? file.path.split('.').last.to_s.downcase : ''
    if file.present? && (file_type.include? 'csv') || (file_type.include? 'xlsx')
      spreadsheet = open_spreadsheet(file)
      @header = spreadsheet.headers
      @data = []
      @import_mapping = ImportMapping.new
      @table_names = %w['Order Product']
      @db_names = Product.column_names
      redirect_to new_import_mapping_path(db_columns: @db_names, header: @header, import_mapping: @import_mapping, table_name: table_name)
    else
      flash[:alert] = 'Try again file not match'
      redirect_to import_mappings_path
    end
  end

  def search_multipack
    @searched_products = Product.ransack('sku_or_title_cont': params[:search_value].downcase.to_s)
                                .result.where(product_type: 'single').limit(20).pluck(:id, :sku, :title)
    respond_to do |format|
      format.json { render json: @searched_products }
    end
  end

  def update_selected
    if params[:id].present? && params[:selected].present?
      product = Product.find_by(id: params[:id])
      product&.update(selected: params[:selected])
      message = { result: product.selected, message: 'Product Updated!' }
    else
      message = { result: 'error', message: 'Product not found' }
    end
    respond_to do |format|
      format.json { render json: message }
    end
  end

  def bulk_update_selected
    Product.where(id: params[:selected]).update_all(selected: true)
    Product.where(id: params[:unselected]).update_all(selected: false)
    message = { result: true, message: 'All products updated' }
    respond_to do |format|
      format.json { render json: message }
    end
  end

  def version
    @product = Product.find_by(id: params[:id])
    @versions = @product&.versions&.reorder('versions.created_at DESC')
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

  def find_product
    @product = Product.find(params[:id])
  end

  def fetch_field_names
    @field_names = []
    @field_names = ExtraFieldName.where(table_name: 'Product').pluck(:field_name)
  end

  def product_params
    params.require(:product)
          .permit(:sku, :title, :photo, :total_stock, :fake_stock, :pending_orders, :allocated,
                  :available_stock, :length, :width, :height, :weight, :pack_quantity, :cost_price, :gst, :vat, :courier_type,
                  :minimum, :maximum, :optimal, :category_id, :product_type, :season_id, :description, :product_location_id,
                  product_forecastings_attributes:
                  %i[id product_id channel_forecasting_id _destroy],
                  barcodes_attributes:
                  %i[id title _destroy],
                  product_suppliers_attributes:
                  %i[id system_user_id product_cost product_sku product_vat _destroy],
                  multipack_products_attributes: %i[id product_id child_id quantity _destroy],
                  extra_field_value_attributes: %i[id field_value])
  end

  def ransack_products
    @q = Product.ransack(params[:q])
    @products = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    @product_exports = ExportMapping.where(table_name: 'Product')
  end

  def build_product
    @product = Product.new(product_params)
    @product.build_extra_field_value
    @product.extra_field_value.field_value = {} if @product.extra_field_value.field_value.nil?
    @field_names.each do |field_name|
      @product.extra_field_value.field_value[field_name.to_s] = params[:"#{field_name}"]
    end
  end

  def csv_create_records(csv)
    found_error, error_message = verify_csv_format(csv)
    if found_error == false
      csv.each.with_index(1) do |row, index|
        hash = row.to_hash
        hash.delete(nil)
        hash['product_type'] = hash['product_type']&.downcase
        hash['vat'] = hash['vat'].to_i
        hash['total_stock'] = hash['total_stock'].to_i
        product = Product.with_deleted.find_or_initialize_by(sku: hash['sku'])
        next product.update(hash) if hash['category_id'].to_i.positive?

        hash['category_id'] = Category.where('title ILIKE ?', hash['category_id'])
                                      .first_or_create(title: hash['category_id']).id
        hash['product_location_id'] = ProductLocation.find_or_create_by(location: hash['product_location_id']).id
        if hash['total_stock'].present? && product.total_stock.present?
          difference = hash['total_stock'].to_i - product.total_stock.to_i
          stock = product.manual_edit_stock.to_i
          stock += difference
          product.update(manual_edit_stock: stock, change_log: "Manual Edit, Spreadsheet, #{stock}, Manual Edit, , #{(hash['total_stock'].to_i - product.unshipped.to_i)}, #{current_user&.personal_detail&.full_name}")
        end
        product.update!(hash)
        Barcode.find_or_create_by(product_id: product.id, title: hash['barcode'])  if hash['barcode'].present?
      end
    else
      flash[:alert] = error_message
    end
  end

  def update_log(stock)
    @product.update(manual_edit_stock: stock, inventory_balance: (@product.total_stock.to_i - @product.unshipped.to_i), change_log: "Manual Edit, #{params[:reason]}, #{stock}, Manual Edit, #{params[:description]}, #{(@product.total_stock.to_i - @product.unshipped.to_i)}, #{current_user&.personal_detail&.full_name}")
    product = @product.product_mappings.last.channel_product if @product.product_mappings.present?
  end

  def load_show
    @product.build_extra_field_value if @product.extra_field_value.nil?
    @product_location = ProductLocation.all
    @forecasting = ChannelForecasting.all
    @channel_listings = ChannelProduct.joins(product_mapping: [product: [multipack_products: :child]]).where('child.id': @product.id)
  end

  def verify_csv_format(csv)
    found_error = false
    error_message = ''
    csv.each.with_index(2) do |row, index|
      if row['title'].nil?
        found_error = true
        error_message = "Title is blank at row number #{index}."
        break
      elsif row['sku'].nil?
        found_error = true
        error_message = "Sku is blank at row number #{index}."
        break
      elsif row['product_type'] == 'single' && row['total_stock'].to_i.negative?
        found_error = true
        error_message = "Stock is null at row number #{index}."
        break
      end
    end
    [found_error, error_message]
  end
end
