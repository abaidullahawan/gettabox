# frozen_string_literal: true

# dashboard
class HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :load_products, :load_suppliers, :load_purchase_order, :load_deliveries, only: %i[dashboard]

  def dashboard
    @total_counts = { products_count: Product.count, suppliers_count: SystemUser.count,
                      purchase_orders_count: PurchaseOrder.count, purchase_deliveries_count: PurchaseDelivery.count }
  end

  def load_products
    @products = Product.ransack(params[:q]).result(distinct: true)
                       .order(created_at: :desc).page(params[:product_page]).per(5)
  end

  def load_suppliers
    @suppliers = SystemUser.ransack(params[:q]).result(distinct: true)
                           .order(created_at: :desc).page(params[:supplier_page]).per(5)
  end

  def load_purchase_order
    @purchase_orders = PurchaseOrder.ransack(params[:q]).result(distinct: true)
                                    .order(created_at: :desc).page(params[:order_page]).per(5)
  end

  def load_deliveries
    @purchase_deliveries = PurchaseDelivery.ransack(params[:q]).result(distinct: true)
                                           .order(created_at: :desc).page(params[:delivery_page]).per(5)
  end
end
