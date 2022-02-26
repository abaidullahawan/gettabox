# frozen_string_literal: true

module ProductsHelper # :nodoc:
  def multi_products_check(multipack_products)
    deduction_arr = []
    multipack_products.each do |multipack_product|
      deduction_arr.push(multipack_product.child.inventory_balance.to_i / multipack_product.quantity.to_i) unless multipack_product.quantity.to_i.zero?
    end
    deduction_arr.min
  end
end
