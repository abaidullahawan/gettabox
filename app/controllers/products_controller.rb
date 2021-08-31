class ProductsController < ApplicationController

  before_action :authenticate_user!
  before_action :find_product, only: [:edit, :update, :show, :destroy]
  before_action :load_resources, only: [:index, :new, :edit, :show, :create, :update]
  # before_action :attributes_for_filter, only: [:index]

  def index
    @q = Product.ransack(params[:q])
    @products = @q.result(distinct: true).page(params[:page]).per(params[:limit])
    export_csv(@products) if params[:export_csv].present?
    new
  end

  def new
    @product = Product.new
    @product.barcodes.build
    @product.product_suppliers.build
  end

  def create
    byebug
    @product = Product.new(product_params)
    if @product.save
      flash[:notice] = "Craeted successfully."
      redirect_to product_path(@product)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      flash[:notice] = "Updated successfully."
      redirect_to product_path(@product)
    else
      render 'edit'
    end
  end

  def show
  end

  def destroy
    @product.destroy
    flash[:notice] = 'Product archive successful'
    redirect_to products_path
  end

  def select2_search
    @products = Product.where("sku like ?", "%#{params[:q]}%")

    respond_to do |format|
      format.json { render json: @products.map{|v| v.serializable_hash(only: [:id, :sku]) } }
    end
  end

  def select2_system_users
    system_users = SystemUser.where("sku like ?", "%#{params[:q]}%")

    respond_to do |format|
      format.json { render json: system_users.map{|v| v.serializable_hash(only: [:id, :sku]) } }
    end
  end

  def export_csv(products)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data products.to_csv, filename: "products-#{Date.today}.csv" }
    end
  end

  def import
    if params[:file].present? && params[:file].path.split(".").last.to_s.downcase == 'csv'
      csv_text = File.read(params[:file])
      csv = CSV.parse(csv_text, :headers => true)
      if csv.headers == Product.column_names
        csv.delete('id')
        csv.each do |row|
          product = Product.find_or_initialize_by(sku: row['sku'])
          if !(product.update(row.to_hash))
            flash[:alert] = "#{product.errors.full_messages} at ID: #{product.id} , Try again."
            redirect_to products_path and return
          end
        end
        flash[:alert] = 'File Upload Successful!'
        redirect_to products_path
      else
        flash[:alert] = 'File not matched! Please change file'
        redirect_to products_path
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
      redirect_to products_path
    end
  end

  def bulk_method
    params[:object_ids].delete('0')
    if params[:object_ids].present?
      params[:object_ids].each do |p|
        product = Product.find(p.to_i)
        product.delete
      end
      flash[:notice] = 'Products archive successfully'
      redirect_to products_path
    else
      flash[:alert] = 'Please select something to perform action.'
    end
  end

  def archive
    @q = Product.only_deleted.ransack(params[:q])
    @products = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    if params[:object_id].present? && Product.restore(params[:object_id])
      flash[:notice] = 'Product restore successful'
      redirect_to archive_products_path
    elsif params[:object_ids].present?
      params[:object_ids].delete('0')
      params[:object_ids].each do |p|
        Product.restore(p.to_i)
      end
      flash[:notice] = 'Products restore successful'
      redirect_to archive_products_path
    else
      flash[:notice] = 'Product cannot be restore'
      redirect_to archive_products_path
    end
  end

  private

  def find_product
    @product = Product.find(params[:id])
  end

  def load_resources
    @system_users = SystemUser.all.map{|v| v.serializable_hash(only: [:id, :name]) }
    @categories = Category.all.map{|v| v.serializable_hash(only: [:id, :title]) }
  end

  def product_params
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
              :_destroy
            ]
    )
  end

end