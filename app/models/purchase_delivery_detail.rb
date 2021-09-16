class PurchaseDeliveryDetail < ApplicationRecord
  acts_as_paranoid

  belongs_to :purchase_delivery
  belongs_to :product

  after_create :product_update
  before_update :product_update_stock
  after_destroy :product_update_delete

  def product_update
    @product = Product.find(self.product.id)
    @stock = @product.total_stock.to_f+self.quantity.to_f
    @product.update(total_stock: @stock)
  end

  def product_update_stock
    return unless self.valid?

    @product = Product.find(self.product.id)
    @stock = @product.total_stock.to_f - (self.quantity_was.to_f - self.quantity.to_f)
    @product.update(total_stock: @stock)
  end

  def product_update_delete
    @product = Product.find(self.product.id)
    @stock = @product.total_stock.to_f-self.quantity.to_f
    @product.update(total_stock: @stock)
  end
end
