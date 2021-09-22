class HomeController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @products = Product.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:page]).per(5)
    @suppliers = SystemUser.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:page]).per(5)
    @purchase_orders = PurchaseOrder.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:page]).per(5)
    @purchase_deliveries = PurchaseDelivery.ransack(params[:q]).result(distinct: true).order(created_at: :desc).page(params[:page]).per(5)
    @total_counts = { products_count: Product.count, suppliers_count: SystemUser.count, purchase_orders_count: PurchaseOrder.count, purchase_deliveries_count: PurchaseDelivery.count }
  end
end
