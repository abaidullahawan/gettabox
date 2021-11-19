# frozen_string_literal: true

# Products Crud
class ProductsController < ApplicationController
  include NewProduct
  include ImportExport

  before_action :authenticate_user!
  before_action :find_product, only: %i[edit update show destroy]
  before_action :product_load_resources, only: %i[index new edit show create update]
  before_action :fetch_field_names, only: %i[new create show index]
  # before_action :attributes_for_filter, only: [:index]
  before_action :new_product, :ransack_products, only: %i[index]
  before_action :build_product, only: %i[create]
  skip_before_action :verify_authenticity_token, only: %i[create update]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    export_csv(@products) if params[:export_csv].present?
    respond_to do |format|
      format.html
      format.csv
      format.pdf do
        render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'products/index.pdf.erb'
      end
    end
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
    if params[:product][:extra_field_value_attributes].present?
      update_extra_fields
    elsif @product.update(product_params)
      flash[:notice] = 'Updated successfully.'
      redirect_to product_path(@product)
    else
      render 'show'
    end
  end

  def show
    @product.build_extra_field_value if @product.extra_field_value.nil?
  end

  def destroy
    @product.destroy
    flash[:notice] = 'Product archive successful'
    redirect_to products_path
  end

  def export_csv(products)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data products.to_csv, filename: "products-#{Date.today}.csv" }
    end
  end

  def import
    if @csv.present?
      @csv.delete('id')
      @csv.delete('created_at')
      @csv.delete('updated_at')
      csv_create_records(@csv)
      flash[:alert] = 'File Upload Successful!'
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
    @searched_products = Product.where('lower(title) LIKE ?', "#{params[:search_value].downcase}%").pluck(:title)
    respond_to do |format|
      format.json  { render json: @searched_products }
    end
  end

  def search_products_by_sku
    @searched_product_by_sku = Product.where('lower(sku) LIKE ?', "#{params[:search_value].downcase}%").pluck(:sku)
    respond_to do |format|
      format.json  { render json: @searched_product_by_sku }
    end
  end

  def search_category
    @searched_category = Category.where('lower(title) LIKE ?', "#{params[:search_value].downcase}%").pluck(:title)
    respond_to do |format|
      format.json  { render json: @searched_category }
    end
  end

  def import_product_file
    if params[:product][:file].present?
      file = params[:product][:file]
      file_type = file.present? ? file.path.split('.').last.to_s.downcase : ''
      if file.present? && (file_type == 'csv' or file_type == 'xlsx')
        spreadsheet = open_spreadsheet(file)
        @header = []
        @data = []
        spreadsheet.first.to_a.each do |row|
          @header.push(row[0].to_s)
        end
        @import_mapping = ImportMapping.new
        @table_names = ['Order', 'Product']
        @db_names = Product.column_names
        @unmatched_columns = @db_names - @header
        redirect_to new_import_mapping_path(db_columns: @db_names, header: @header, import_mapping: @import_mapping)
      else
        flash[:alert] = 'Try again file not match'
        redirect_to product_mappings_path
      end
    end
  end

  private

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then CSV.parse(File.read(file.path).force_encoding("ISO-8859-1").encode("utf-8", replace: nil), :headers => true)
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
          .permit(:sku, :title, :photo, :total_stock, :fake_stock, :pending_orders, :allocated_orders,
                  :available_stock, :length, :width, :height, :weight, :pack_quantity, :cost_price, :gst, :vat,
                  :minimum, :maximum, :optimal, :category_id, :product_type, :season_id, :description,
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
    csv.each do |row|
      product = Product.with_deleted.find_or_initialize_by(sku: row['sku'])
      next product.update(row.to_hash) if row['category_id'].to_i.positive?

      row['category_id'] = Category.where('title ILIKE ?', row['category_id'])
                                   .first_or_create(title: row['category_id']).id
      row = row.to_hash
      row.delete(nil)
      product.update!(row)
    end
  end
end
