# frozen_string_literal: true

# PurchaseDeliveries Crud
class PurchaseDeliveriesController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :find_purchase_delivery, only: %i[show edit update destroy]
  after_action :restore_childs, only: :restore
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    @q = PurchaseDelivery.ransack(params[:q])
    @purchase_deliveries = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@purchase_deliveries) if params[:export_csv].present?
  end

  def new
    @purchase_order = PurchaseOrder.find(params[:purchase_order_id])
    if @purchase_order.order_status == 'completed'
      flash[:notice] = 'Order Delivery is already completed.'
      redirect_to purchase_order_path(@purchase_order)
    else
      @purchase_order_details = @purchase_order.purchase_order_details
      @purchase_delivery = PurchaseDelivery.new
      @purchase_delivery.purchase_delivery_details.build
    end
  end

  def create
    @purchase_delivery = PurchaseDelivery.new(purchase_delivery_params)
    if @purchase_delivery.save
      id = @purchase_delivery.purchase_order_id
      PurchaseOrder.find(id).update(order_status: params[:order_status])
      flash[:notice] = 'Order Delivered Successfully.'
      redirect_to purchase_order_path(id)
    else
      flash.now[:notice] = 'Not Succesfully Delivered.'
      render 'new'
    end
  end

  def show
    @supplier = PurchaseOrder.find(@purchase_delivery.purchase_order_id).supplier_id
  end

  def edit; end

  def update
    if @purchase_delivery.purchase_order.order_status == 'completed'
      flash[:notice] = 'Order Delivery is already completed.'
      redirect_to purchase_delivery_path(@purchase_delivery)
    elsif @purchase_delivery.update(purchase_delivery_params)
      @purchase_delivery.purchase_order.update(order_status: params[:order_status])
      flash[:notice] = 'Order Delivery updated successfully.'
      redirect_to purchase_delivery_path(@purchase_delivery)
    else
      flash.now[:notice] = 'Order Delivery not updated.'
      render 'show'
    end
  end

  def destroy
    if @purchase_delivery.destroy
      flash[:notice] = 'Purchase Delivery archive successfully.'
      redirect_to purchase_deliveries_path
    else
      flash.now[:notice] = 'Purchase Delivery not archived.'
      render purchase_deliveries_path
    end
  end

  def export_csv(purchase_deliveries)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data purchase_deliveries.to_csv, filename: "purchase-deliveries-#{Date.today}.csv" }
    end
  end

  def import
    if @csv.present?
      csv_create_records(@csv)
      flash[:notice] = 'File Upload Successful!'
    end
    redirect_to purchase_deliveries_path
  end

  def bulk_method
    redirect_to purchase_deliveries_path
  end

  def archive
    @q = PurchaseDelivery.only_deleted.ransack(params[:q])
    @purchase_deliveries = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_purchase_deliveries_path
  end

  def permanent_delete
    if params[:object_id].present? && PurchaseDelivery.only_deleted.find(params[:object_id]).really_destroy!
      flash[:notice] = 'Purchase Delivery deleted successfully'
    else
      flash[:notice] = 'Purchase Delivery cannot be deleted/Please select something to delete'
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
      @stock = @product.total_stock.to_f + detail.quantity.to_f
      @available_stock = @product.available_stock.to_f + detail.quantity.to_f
      @product.update(total_stock: @stock, available_stock: @available_stock, change_log: "Purchase Order, #{detail.id}, #{detail.purchase_order.system_user.name}, Purchase Order Recieved, #{detail.purchase_order.purchase_order_details.last.cost_price.to_i}")
    end
  end

  def purchase_delivery_params
    params.require(:purchase_delivery).permit(
      :purchase_order_id,
      :total_bill,
      purchase_delivery_details_attributes: %i[
        id purchase_delivery_id
        product_id cost_price
        quantity missing
        deleted_at demaged
      ]
    )
  end

  def csv_create_records(csv)
    csv.each do |row|
      data = PurchaseDelivery.with_deleted.find_or_initialize_by(id: row['id'])
      if !data.update(row.to_hash)
        flash[:alert] = "#{data.errors.full_messages} at ID: #{data.id} , Try again"
      else
        data.update(user_type: 'supplier')
      end
    end
  end
end
