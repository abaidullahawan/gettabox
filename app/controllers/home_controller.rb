class HomeController < ApplicationController
  before_action :authenticate_user!, except: %i[ info ]

  def dashboard
    @products = Product.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:product_page]).per(5)
    @suppliers = SystemUser.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:supplier_page]).per(5)
    @purchase_orders = PurchaseOrder.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:order_page]).per(5)
    @purchase_deliveries = PurchaseDelivery.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:delivery_page]).per(5)
    @total_counts = { products_count: Product.count, suppliers_count: SystemUser.count, purchase_orders_count: PurchaseOrder.count, purchase_deliveries_count: PurchaseDelivery.count }
  end

  def info
    redirect_to home_path if current_user.present?
  end
end
