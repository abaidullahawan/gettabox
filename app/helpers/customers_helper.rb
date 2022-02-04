# frozen_string_literal: true

module CustomersHelper # :nodoc:
  def unmap_customer_order(customers)
    customers.channel_orders.where.not(stage: %w[unable_to_find_sku unmapped_product_sku])&.last
  end
end
