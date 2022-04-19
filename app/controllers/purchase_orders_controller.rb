# frozen_string_literal: true

# getting purchase orders and creating
class PurchaseOrdersController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :find_purchase_order, only: %i[show edit update destroy send_mail_to_supplier]
  before_action :build_purchase_order, only: %i[new]
  before_action :find_supplier, only: %i[show edit send_mail_to_supplier]
  before_action :sum_of_stock, only: %i[show send_mail_to_supplier]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, :restore_childs, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    @q = PurchaseOrder.ransack(params[:q])
    @purchase_orders = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@purchase_orders) if params[:export_csv].present?
  end

  def new
    @supplier = params[:supplier]
    @categories = Product.joins(:product_suppliers, :category).where('product_suppliers.system_user_id': @supplier)
                         .pluck('categories.id', 'categories.title').uniq
    @products = {}
    @categories.each do |category|
      product = Product.joins(:product_suppliers, :category).where('product_suppliers.system_user_id': @supplier,
                                                                   'category.id': category)
      @products[category.first] = product
    end
  end

  def create
    @supplier = SystemUser.find(params[:purchase_order][:supplier_id])
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    @purchase_order.order_status_created!
    # @purchase_order.delivery_address = @supplier.supplier_address
    # @purchase_order.invoice_address = GeneralSetting.first.address
    if @purchase_order.save
      flash[:notice] = 'Purchase Order created successfully.'
      redirect_to purchase_order_path(@purchase_order)
    else
      flash.now[:notice] = 'Purchase Order not created.'
      render 'new'
    end
  end

  def show
    if params[:single_csv].present?
      single_csv(@purchase_order)
    else
      respond_to do |format|
        format.html
        format.pdf do
          render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'purchase_orders/show.pdf.erb'
        end
      end
    end
  end

  def send_mail_to_supplier
    @template = EmailTemplate.where(template_name: 'PurchaseOrder').first
    @pdf_file = render(pdf: 'file.pdf', template: 'purchase_orders/show.pdf.erb', filename: 'Purchase Order')
    pdf = [[@pdf_file, 'Purchase Order']]
    email = @purchase_order.system_user.email
    name = @purchase_order.system_user.name
    subject = @template&.subject
    body = @template&.body
    PurchaseOrderMailer.send_email(pdf, subject, email, name, body).deliver if email.present?
    @purchase_order.order_status_sent!
  end

  def single_csv(purchase_order)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data PurchaseOrder.to_single_csv(purchase_order), filename: "purchase-order-#{Date.today}.csv" }
    end
  end

  def edit
    @categories = Product.joins(:product_suppliers, :category)
                         .where('product_suppliers.system_user_id': @supplier)
                         .pluck('categories.id', 'categories.title')
                         .uniq
  end

  def update
    if @purchase_order.update(purchase_order_params)
      flash[:notice] = 'Purchase Order updated successfully.'
      redirect_to purchase_order_path(@purchase_order)
    else
      flash.now[:notice] = 'Purchase Order not updated.'
      render 'show'
    end
  end

  def destroy
    if @purchase_order.destroy
      flash[:notice] = 'Purchase Order archive successfully.'
      redirect_to purchase_orders_path
    else
      flash.now[:notice] = 'Purchase Order not archived.'
      render purchase_orders_path
    end
  end

  def export_csv(purchase_orderss)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data purchase_orderss.to_csv, filename: "purchase-orders-#{Date.today}.csv" }
    end
  end

  def import
    if @csv.present?
      csv_create_records(@csv)
      flash[:notice] = 'File Upload Successful!'
    end
    redirect_to purchase_orderss_path
  end

  def bulk_method
    redirect_to purchase_orders_path
  end

  def archive
    @q = PurchaseOrder.only_deleted.ransack(params[:q])
    @purchase_orders = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_purchase_orders_path
  end

  private

  def find_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  def restore_childs
    child_ids = PurchaseOrderDetail.only_deleted.where(purchase_delivery_id: params[:object_id]).pluck(:id)
    PurchaseOrderDetail.restore(child_ids)
  end

  def purchase_order_params
    params.require(:purchase_order).permit(
      :supplier_id, :total_bill, :payment_method,
      # :delivery_address,
      # :invoice_address,
      purchase_order_details_attributes: %i[
        id purchase_order_id product_id
        cost_price vat quantity missing deleted_at demaged
      ],
      addresses_attributes: %i[
        id company address city region postcode country
      ]
    )
  end

  def build_purchase_order
    @purchase_order = PurchaseOrder.new
    @purchase_order.purchase_order_details.build
    # @purchase_order.addresses.build
  end

  def find_supplier
    @supplier = @purchase_order.supplier_id
  end

  def sum_of_stock
    @deliverd = PurchaseOrder.where(id: @purchase_order.id).joins(purchase_deliveries: :purchase_delivery_details)
                             .group(:product_id).sum(:quantity)
    @missing = PurchaseOrder.where(id: @purchase_order.id).joins(purchase_deliveries: :purchase_delivery_details)
                            .group(:product_id).sum(:missing)
    @demaged = PurchaseOrder.where(id: @purchase_order.id).joins(purchase_deliveries: :purchase_delivery_details)
                            .group(:product_id).sum(:demaged)
    @deliveries = @purchase_order.purchase_deliveries
  end

  def csv_create_records(csv)
    csv.each do |row|
      data = PurchaseOrder.with_deleted.find_or_initialize_by(id: row['id'])
      if !data.update(row.to_hash)
        flash[:alert] = "#{data.errors.full_messages} at ID: #{data.id} , Try again"
      else
        data.update(user_type: 'supplier')
      end
    end
  end
end
