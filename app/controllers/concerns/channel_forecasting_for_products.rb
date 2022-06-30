# frozen_string_literal: true

# Channel Forecasting for Products(Anticipate)
module ChannelForecastingForProducts
  extend ActiveSupport::Concern
  def concern_channel_forecasting_for_products(order_item, product, order)
    if product.product_type_multiple?
      check_forcasting = product.multipack_products.map { |multi| multi.child.product_forecasting.present? }
      return if check_forcasting.any?(false)

      product.multipack_products.each do |multi|
        product = multi.child
        product = Product.find(product.id)
        calculation_for_allocation(product, order, order_item)
      end
    else
      return unless product.product_forecasting.present?

      calculation_for_allocation(product, order, order_item)
    end
  end

  def calculation_for_allocation(product, order, order_item)
    channel_type = order.channel_type
    if (product.forecasting.include? channel_type) && (product.forecasting[channel_type].include? 'product_units') && product.forecasting[channel_type]['product_units'].positive?
      allocation_by_anticipate_based_on_product_units(order_item, channel_type, product)
    elsif (product.forecasting.include? channel_type) && (product.forecasting[channel_type].include? 'order_units') && product.forecasting[channel_type]['order_units'].positive?
      allocation_by_anticipate_based_on_order_units(channel_type, order)
    end
  end

  def allocation_by_anticipate_based_on_product_units(order_item, channel_type, product)
    product = Product.find(product.id)
    product_forecasting = product.forecasting
    type_number = product_forecasting[channel_type]['product_units']
    type_number = product.available_stock.to_i + type_number
    return unless type_number.positive? && type_number >= order_item.ordered

    product_forecasting[channel_type]['product_units'] = type_number - order_item.ordered
    product.update(
      allocated: product.allocated.to_i + order_item.ordered,
      allocated_orders: product.allocated_orders.to_i + 1, forecasting: product_forecasting
    )
    order_item.update(allocated: true)
  end

  def allocation_by_anticipate_based_on_order_units(channel_type, order)
    return if order.channel_order_items.map(&:allocated).all?(true)

    order.channel_order_items.each do |item|
      next if item.allocated

      product = item.channel_product.product_mapping.product
      if product.product_type_single?
        product = Product.find(product.id)
        product_forecasting = product.forecasting
        type_number = product_forecasting[channel_type]['order_units']
        if type_number.positive?
          product_forecasting[channel_type]['order_units'] = type_number - 1
          product.update(
            allocated: product.allocated.to_i + item.ordered,
            allocated_orders: product.allocated_orders.to_i + 1, forecasting: product_forecasting
          )
          item.update(allocated: true)
        end
      else
        check = product.multipack_products.map { |m| m.child.forecasting[channel_type]['order_units'].positive? }
        next unless check.any?(false)

        product.multipack_products.each do |multipack|
          child = multipack.child
          child = Product.find(child.id)
          quantity = multipack.quantity
          ordered = (item.ordered * quantity)
          product_forecasting = child.forecasting
          type_number = product_forecasting[channel_type]['order_units']
          product_forecasting[channel_type]['order_units'] = type_number - 1
          child.update(
            allocated: child.allocated.to_i + ordered,
            allocated_orders: child.allocated_orders.to_i + 1, forecasting: product_forecasting
          )
          item.update(allocated: true)
        end
      end
    end
  end
end
