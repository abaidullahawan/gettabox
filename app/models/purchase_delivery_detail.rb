class PurchaseDeliveryDetail < ApplicationRecord
  belongs_to :purchase_delivery
  belongs_to :product

  after_create :product_update

  def product_update
    @product = Product.find(self.product.id)
    @stock = @product.total_stock.to_f+self.quantity.to_f
    @product.update(total_stock: @stock)
  end
end
