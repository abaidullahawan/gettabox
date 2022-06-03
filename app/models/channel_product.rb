# frozen_string_literal: true

# products from apo
class ChannelProduct < ApplicationRecord
  has_one :product_mapping
  belongs_to :assign_rule, optional: true
  belongs_to :channel_forecasting, optional: true
  has_many :channel_order_items
  after_update :update_channel_quantity, if: :saved_change_to_status?

  enum channel_type: {
    ebay: 0,
    amazon: 1,
    cloud_commerce: 4
  }, _prefix: true

  enum status: {
    unmapped: 0,
    mapped: 1
  }, _prefix: true

  def update_channel_quantity
    return unless status_mapped?

    product = product_mapping.product
    quantity = product.inventory_balance.to_i
    selling_unit = Selling&.last&.quantity.to_i
    if product.product_type_single?
      channel_quantity = if channel_type_ebay?
                           Selling&.last&.quantity.to_i < quantity ? selling_unit : [quantity, 0].max
                         else
                           product.inventory_balance
                         end
    else
      multipack_products = product.multipack_products
      deduction_quantity = multi_products_check(multipack_products)
      channel_quantity = if channel_type_ebay?
                           selling_unit < deduction_quantity.to_i ? selling_unit : [deduction_quantity.to_i, 0].max
                         else
                           [deduction_quantity.to_i, 0].max
                         end
    end
    update_columns(item_quantity: channel_quantity, item_quantity_changed: true)
  end

  def multi_products_check(multipack_products)
    deduction_arr = []
    multipack_products.each do |multipack_product|
      next if multipack_product.quantity.to_i.zero?

      deduction_arr.push(multipack_product.child.inventory_balance.to_i / multipack_product.quantity.to_i)
    end
    deduction_arr.min
  end
end
