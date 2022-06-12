# frozen_string_literal: true

# products from apo
class ChannelProduct < ApplicationRecord
  has_one :product_mapping
  belongs_to :assign_rule, optional: true
  belongs_to :channel_forecasting, optional: true
  has_many :channel_order_items
  after_update :update_item_quantity, if: :saved_change_to_status?
  after_update :update_channel_quantity

  enum channel_type: {
    ebay: 0,
    amazon: 1,
    cloud_commerce: 4
  }, _prefix: true

  enum status: {
    unmapped: 0,
    mapped: 1
  }, _prefix: true

  def update_item_quantity
    return unless status_mapped?

    product = product_mapping.product
    stock = product.inventory_balance.to_i + product.fake_stock.to_i
    selling_unit = Selling&.last&.quantity.to_i
    if product.product_type_single?
      quantity = if channel_type_ebay?
                     selling_unit < stock ? selling_unit : [stock, 0].max
                   else
                     stock
                   end
    else
      multipack_products = product.multipack_products
      deduction_quantity = multi_products_check(multipack_products)
      quantity = if channel_type_ebay?
                   selling_unit < deduction_quantity.to_i ? selling_unit : [deduction_quantity.to_i, 0].max
                 else
                   [deduction_quantity.to_i, 0].max
                 end
    end
    update_columns(item_quantity: quantity, channel_quantity: quantity + buffer_quantity.to_i, item_quantity_changed: true) unless item_quantity.to_i.eql? quantity.to_i
  end

  def multi_products_check(multipack_products)
    deduction_arr = []
    multipack_products.each do |multipack_product|
      next if multipack_product.quantity.to_i.zero?

      deduction_arr.push((multipack_product.child.inventory_balance.to_i + multipack_product.child.fake_stock.to_i) / multipack_product.quantity.to_i)
    end
    deduction_arr.min
  end

  def update_channel_quantity
    return unless saved_change_to_attribute?(:item_quantity) || saved_change_to_attribute?(:channel_quantity) || saved_change_to_attribute?(:buffer_quantity)

    selling_unit = Selling&.last&.quantity.to_i
    quantity = channel_type_ebay? ? (selling_unit < item_quantity) ? selling_unit : item_quantity : item_quantity
    quantity = [quantity, 0].max
    buffered_quantity = quantity + buffer_quantity.to_i
    buffered_quantity = channel_type_ebay? ? (selling_unit < buffered_quantity) ? selling_unit : buffered_quantity : buffered_quantity
    update_columns(item_quantity: quantity, channel_quantity: buffered_quantity)
  end
end
