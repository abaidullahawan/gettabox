class PurchaseDeliveryDetail < ApplicationRecord
  acts_as_paranoid

  belongs_to :purchase_delivery
  belongs_to :product

  after_create :product_update
  before_update :product_update_stock
  after_destroy :product_update_delete

  def product_update
    @product = Product.find(product.id)
    @stock = @product.total_stock.to_f + quantity.to_f
    @product.update(total_stock: @stock)
  end

  def product_update_stock
    return unless valid?

    @product = Product.find(product.id)
    @stock = @product.total_stock.to_f - (quantity_was.to_f - quantity.to_f)
    @product.update(total_stock: @stock)
  end

  def product_update_delete
    @product = Product.find(product.id)
    @stock = @product.total_stock.to_f - quantity.to_f
    @product.update(total_stock: @stock)
  end
end
