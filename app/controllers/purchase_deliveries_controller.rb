class PurchaseDeliveriesController < ApplicationController

  before_action :authenticate_user!
  before_action :find_purchase_delivery, only: [:show, :edit, :update, :destroy]
  after_action :restore_childs, only: :restore

  def index
    @q = PurchaseDelivery.ransack(params[:q])
    @purchase_deliveries = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@purchase_deliveries) if params[:export_csv].present?
  end

  def new
    @purchase_delivery = PurchaseDelivery.new
    @purchase_delivery.purchase_delivery_details.build
    @purchase_order = PurchaseOrder.find(params[:purchase_order_id])
    @purchase_order_details = @purchase_order.purchase_order_details
  end

  def create
    @purchase_delivery = PurchaseDelivery.new(purchase_delivery_params)
    if @purchase_delivery.save
      flash[:notice] = "Purchase Order created successfully."
      redirect_to purchase_delivery_path(@purchase_delivery)
    else
      flash.now[:notice] = "Purchase Order not created."
      render 'new'
    end
  end

  def show
    @supplier = PurchaseOrder.find(@purchase_delivery.purchase_order_id).supplier_id
  end

  def edit
  end

  def update
    if @purchase_delivery.update(purchase_delivery_params)
      flash[:notice] = "Purchase Order updated successfully."
      redirect_to purchase_delivery_path(@purchase_delivery)
    else
      flash.now[:notice] = "Purchase Order not updated."
      render 'show'
    end
  end

  def destroy
    if @purchase_delivery.destroy
      flash[:notice] = "Purchase Order archive successfully."
      redirect_to purchase_deliveries_path
    else
      flash.now[:notice] = "Purchase Order not archived."
      render purchase_deliveries_path
    end
  end

  def export_csv(purchase_deliveries)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data purchase_deliveries.to_csv, filename: "purchase-orders-#{Date.today}.csv" }
    end
  end

  def import
    if params[:file].present? && params[:file].path.split(".").last.to_s.downcase == 'csv'
      csv_text = File.read(params[:file])
      csv = CSV.parse(csv_text, :headers => true)
      if csv.headers == PurchaseDelivery.column_names.excluding('user_type')
        csv.each do |row|
          data = PurchaseDelivery.find_or_initialize_by(id: row['id'])
          if !(data.update(row.to_hash))
            flash[:alert] = "#{data.errors.first.full_message} at ID: #{data.id} , Try again"
            redirect_to purchase_deliveries_path and return
          else
            data.update(user_type: 'supplier')
          end
        end
        flash[:alert] = 'File Upload Successful!'
        redirect_to purchase_deliveries_path
      else
        flash[:alert] = 'File not matched! Please change file'
        redirect_to purchase_deliveries_path
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
      redirect_to purchase_deliveries_path
    end
  end

  def bulk_method
    params[:object_ids].delete('0')
    if params[:object_ids].present?
      params[:object_ids].each do |p|
        product = PurchaseDelivery.find(p.to_i)
        product.delete
      end
      flash[:notice] = 'Purchase Orders archive successfully'
      redirect_to purchase_deliveries_path
    else
      flash[:alert] = 'Please select something to perform action.'
      redirect_to purchase_deliveries_path
    end
  end

  def archive
    @q = PurchaseDelivery.only_deleted.ransack(params[:q])
    @purchase_deliveries = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    if params[:object_id].present? && PurchaseDelivery.restore(params[:object_id])
      flash[:notice] = 'Purchase Order restore successful'
      redirect_to archive_purchase_deliveries_path
    elsif params[:object_ids].present?
      params[:object_ids].delete('0')
      params[:object_ids].each do |p|
        PurchaseDelivery.restore(p.to_i)
      end
      flash[:notice] = 'Purchase Orders restore successful'
      redirect_to archive_purchase_deliveries_path
    else
      flash[:notice] = 'Purchase Order cannot be restore'
      redirect_to archive_purchase_deliveries_path
    end
  end

  def permanent_delete
    if params[:object_id].present? && PurchaseDelivery.only_deleted.find(params[:object_id]).really_destroy!
      flash[:notice] = 'Purchase Order deleted successfully'
      redirect_to archive_purchase_deliveries_path
    else
      flash[:notice] = 'Purchase Order cannot be deleted/Please select something to delete'
      redirect_to archive_purchase_deliveries_path
    end
  end

  private
    def find_purchase_delivery
      @purchase_delivery = PurchaseDelivery.find(params[:id])
    end

    def restore_childs
      @purchase_deliveries = PurchaseDeliveryDetail.only_deleted.where(purchase_delivery_id: params[:object_id])
      @purchase_deliveries&.each do |detail|
        return unless detail.restore

        @product = Product.find(detail.product.id)
        @stock = @product.total_stock.to_f+detail.quantity.to_f
        @product.update(total_stock: @stock)
      end
    end

    def purchase_delivery_params
      params.require(:purchase_delivery).permit(
        :purchase_order_id,
        :total_bill,
        purchase_delivery_details_attributes:[
          :id,
          :purchase_delivery_id,
          :product_id,
          :cost_price,
          :quantity,
          :missing,
          :deleted_at,
          :demaged
        ]
      )
    end

end
