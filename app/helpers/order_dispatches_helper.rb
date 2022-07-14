# frozen_string_literal: true

module OrderDispatchesHelper # :nodoc:
  def postage_mapping(postage)
    postage_hash = {'Standard' => '0.0', 'SecondDay' => '2.99', 'Expedited' => '2.99'}

    return postage if postage.to_f.to_s.eql? postage

    postage_hash[postage]
  end

  def ordered_products_count(order)
    count = []
    order.channel_order_items.each do |item|
      product = item.channel_product&.product_mapping&.product
      next unless product.present?

      if product.product_type_multiple?
        product.multipack_products.each do |multipack|
          count << multipack.quantity.to_i * item.ordered.to_i
        end
      else
        count << item.ordered
      end
    end
    count.sum
  end
end
