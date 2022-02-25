# frozen_string_literal: true

module ProductsHelper # :nodoc:
  def multi_products_check(multipack_products)
    deduction_arr = []
    multipack_products.each do |multipack_product|
      deduction_arr.push(multipack_product.child.total_stock.to_i / multipack_product.quantity.to_i)
    end
    deduction_arr.min
  end
end
