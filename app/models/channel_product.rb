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
                  stock > selling_unit ? selling_unit : stock
                 else
                  stock
                 end
    else
      multipack_products = product.multipack_products
      deduction_quantity = multi_products_check(multipack_products)
      quantity = if channel_type_ebay?
                   deduction_quantity.to_i > selling_unit ? selling_unit : deduction_quantity.to_i
                 else
                   deduction_quantity.to_i
                 end
    end
    buffered_quantity = [quantity + buffer_quantity.to_i, 0].max
    buffered_quantity = nested_ternary(buffered_quantity, selling_unit, channel_type_ebay?)
    update_columns(item_quantity: quantity, channel_quantity: buffered_quantity, item_quantity_changed: true) unless item_quantity.to_i.eql? quantity.to_i
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
    product = product_mapping.product
    product = Product.find_by(id: product.id)
    quantity = if product.product_type_single?
                 product.inventory_balance
               else
                 product.multipack_products.map { |mp| mp.child.inventory_balance.to_i / mp.quantity.to_i }.min
               end
    quantity = nested_ternary(quantity, selling_unit, channel_type_ebay?)
    quantity = [quantity, 0].max
    buffered_quantity = quantity + buffer_quantity.to_i

    buffered_quantity = nested_ternary(buffered_quantity, selling_unit, channel_type_ebay?)
    buffered_quantity = [buffered_quantity.to_i, 0].max

    update_columns(item_quantity: quantity, channel_quantity: buffered_quantity)
  end

  def nested_ternary(quantity, selling_unit, ebay_check)
    if ebay_check
      quantity > selling_unit ? selling_unit : quantity
    else
      quantity
    end
  end
end
