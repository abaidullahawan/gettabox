# frozen_string_literal: true

# delivery detail of product
class PurchaseDeliveryDetail < ApplicationRecord
  acts_as_paranoid

  belongs_to :purchase_delivery
  belongs_to :product

  after_create :product_update
  before_update :product_update_stock
  after_destroy :product_update_delete

  def product_update
    @product = Product.find(product.id)
    @stock = @product.total_stock.to_i + quantity.to_i
    @available_stock = @product.available_stock.to_i + quantity.to_i
    inventory_balance = @stock - @product.unshipped.to_i
    @product.update(total_stock: @stock, change_log: "Purchase Order, #{purchase_delivery.id}, #{purchase_delivery.purchase_order.system_user.name}, Purchase Order Recieved, #{(purchase_delivery.purchase_order.purchase_order_details.last.cost_price.to_f * quantity.to_i)}, #{inventory_balance.to_i}, #{quantity.to_i}")
  end

  def product_update_stock
    return unless valid?

    @product = Product.find(product.id)
    @stock = @product.total_stock.to_i - (quantity_was.to_i - quantity.to_i)
    @available_stock = @product.available_stock.to_i  - (quantity_was.to_i - quantity.to_i)
    inventory_balance = @stock - @product.unshipped.to_i
    @product.update(total_stock: @stock, available_stock: @available_stock, change_log: "Purchase Order, #{purchase_delivery.id}, #{purchase_delivery.purchase_order.system_user.name}, Purchase Order Recieved, #{(purchase_delivery.purchase_order.purchase_order_details.last.cost_price.to_f * quantity.to_i)}, #{inventory_balance.to_i}, #{quantity.to_i}")
  end

  def product_update_delete
    @product = Product.find(product.id)
    @stock = @product.total_stock.to_i - quantity.to_i
    @available_stock = @product.available_stock.to_i - quantity.to_i
    inventory_balance = @stock - @product.unshipped.to_i
    @product.update(total_stock: @stock, available_stock: @available_stock, change_log: "Purchase Order, #{purchase_delivery.id}, #{purchase_delivery.purchase_order.system_user.name}, Purchase Order Recieved, #{(purchase_delivery.purchase_order.purchase_order_details.last.cost_price.to_f * quantity.to_i)}, #{inventory_balance.to_i}, #{quantity.to_i}")
  end
end
