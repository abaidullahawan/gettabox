class PurchaseOrdersController < ApplicationController

  before_action :authenticate_user!
  before_action :find_purchase_order, only: [:show, :edit, :update, :destroy]

  def index
    @q = PurchaseOrder.ransack(params[:q])
    @purchase_orders = @q.result(distinct: true).page(params[:page]).per(params[:limit])
    export_csv(@purchase_orders) if params[:export_csv].present?

    @purchase_order = PurchaseOrder.new
  end

  def new
    @purchase_order = PurchaseOrder.new
    @purchase_order.purchase_order_details.build
    @supplier = params[:supplier]
    @categories = Product.joins(:product_suppliers,:category).where('product_suppliers.system_user_id': @supplier).pluck('categories.id','categories.title').uniq
    @products = Hash.new
    @categories.each do |category|
      product = Product.joins(:product_suppliers,:category).where('product_suppliers.system_user_id': @supplier, 'category.id': category)
      @products[category.first] = product
    end
  end

  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    if @purchase_order.save
      flash[:notice] = "Purchase Order created successfully."
      redirect_to purchase_orderss_path
    else
      flash.now[:notice] = "Purchase Order not created."
      render 'new'
    end
  end

  def show
  end

  def edit
  end

  def update
    if @purchase_order.update(purchase_order_params)
      flash[:notice] = "Purchase Order updated successfully."
      redirect_to purchase_orderss_path
    else
      flash.now[:notice] = "Purchase Order not updated."
      render 'edit'
    end
  end

  def destroy
    if @purchase_order.destroy
      flash[:notice] = "Purchase Order archive successfully."
      redirect_to purchase_orderss_path
    else
      flash.now[:notice] = "Purchase Order not archived."
      render purchase_orderss_path
    end
  end

  def export_csv(purchase_orderss)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data purchase_orderss.to_csv, filename: "purchase-orders-#{Date.today}.csv" }
    end
  end

  def import
    if params[:file].present? && params[:file].path.split(".").last.to_s.downcase == 'csv'
      csv_text = File.read(params[:file])
      csv = CSV.parse(csv_text, :headers => true)
      if csv.headers == PurchaseOrder.column_names.excluding('user_type')
        csv.each do |row|
          data = PurchaseOrder.find_or_initialize_by(id: row['id'])
          if !(data.update(row.to_hash))
            flash[:alert] = "#{data.errors.first.full_message} at ID: #{data.id} , Try again"
            redirect_to purchase_orderss_path and return
          else
            data.update(user_type: 'supplier')
          end
        end
        flash[:alert] = 'File Upload Successful!'
        redirect_to purchase_orderss_path
      else
        flash[:alert] = 'File not matched! Please change file'
        redirect_to purchase_orderss_path
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
      redirect_to purchase_orderss_path
    end
  end

  def bulk_method
    params[:object_ids].delete('0')
    if params[:object_ids].present?
      params[:object_ids].each do |p|
        product = PurchaseOrder.find(p.to_i)
        product.delete
      end
      flash[:notice] = 'Purchase Orders archive successfully'
      redirect_to purchase_orderss_path
    else
      flash[:alert] = 'Please select something to perform action.'
    end
  end

  def archive
    @q = PurchaseOrder.only_deleted.ransack(params[:q])
    @purchase_orders = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    if params[:object_id].present? && PurchaseOrder.restore(params[:object_id])
      flash[:notice] = 'Purchase Order restore successful'
      redirect_to archive_purchase_orderss_path
    elsif params[:object_ids].present?
      params[:object_ids].delete('0')
      params[:object_ids].each do |p|
        PurchaseOrder.restore(p.to_i)
      end
      flash[:notice] = 'Purchase Orders restore successful'
      redirect_to archive_purchase_orderss_path
    else
      flash[:notice] = 'Purchase Order cannot be restore'
      redirect_to archive_purchase_orderss_path
    end
  end

  private
    def find_purchase_order
      @purchase_order = PurchaseOrder.find(params[:id])
    end

    def purchase_order_params
      params.require(:purchase_orders).permit(:user_type, :name, :photo, :payment_method, :days_for_payment, :days_for_order_to_completion, :days_for_completion_to_delivery, :currency_symbol, :exchange_rate)
    end

end