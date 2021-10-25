# frozen_string_literal: true

# Products Crud
class ProductsController < ApplicationController
  include NewProduct

  before_action :authenticate_user!
  before_action :find_product, only: %i[edit update show destroy]
  before_action :product_load_resources, only: %i[index new edit show create update]
  before_action :fetch_field_names, only: %i[new create show index]
  # before_action :attributes_for_filter, only: [:index]
  before_action :new_product, :ransack_products, only: %i[index]
  before_action :build_product, only: %i[create]
  skip_before_action :verify_authenticity_token, only: %i[create update]
  before_action :filter_object_ids, only: %i[bulk_method restore]

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
    if params[:file].present? && params[:file].path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(params[:file])
      csv = CSV.parse(csv_text, headers: true)
      if csv.headers == Product.column_names
        csv.delete('id')
        csv.each do |row|
          product = Product.find_or_initialize_by(sku: row['sku'])
          unless product.update(row.to_hash)
            flash[:alert] = "#{product.errors.full_messages} at ID: #{product.id} , Try again."
            redirect_to products_path
          end
        end
        flash[:alert] = 'File Upload Successful!'
      else
        flash[:alert] = 'File not matched! Please change file'
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    redirect_to products_path
  end

  def bulk_method
    if params[:object_ids].present?
      params[:object_ids].each do |p|
        product = Product.find(p.to_i)
        product.delete
      end
      flash[:notice] = 'Products archive successfully'
    else
      flash[:alert] = 'Please select something to perform action.'
    end
    redirect_to products_path
  end

  def archive
    @q = Product.only_deleted.ransack(params[:q])
    @products = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    if params[:object_id].present? && Product.restore(params[:object_id])
      flash[:notice] = 'Product restore successful'
    elsif params[:commit] == 'Delete' && params[:object_ids].present?
      params[:object_ids].each do |id|
        Product.only_deleted.find(id).really_destroy!
      end
      flash[:notice] = 'Products deleted successfully'
    elsif params[:commit] == 'Restore' && params[:object_ids].present?
      params[:object_ids].each do |p|
        Product.restore(p.to_i)
      end
      flash[:notice] = 'Products restored successfully'
    else
      flash[:notice] = 'Please select something to perform action'
    end
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

  private

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
                  :hst, :pst, :qst, :minimum, :maximum, :optimal, :category_id, :product_type, :season_id, :description,
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

  def filter_object_ids
    params[:object_ids].delete('0') if params[:object_ids].present?
  end
end
