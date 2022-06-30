# frozen_string_literal: true

# Channel Forecasting for Products(Safe Stock)
module ChannelForecastingForSafeStock
  extend ActiveSupport::Concern
  def concern_channel_forecasting_for_safe_stock(order_item, product, order)
    @avoid_allocation = []

    if product.product_type_multiple?
      check_forcasting = product.multipack_products.map { |multi| multi.child.product_forecasting.present? }
      return if check_forcasting.any?(false)

      product.multipack_products.each do |multi|
        product = multi.child
        product = Product.find(product.id)
        allocation_for_safe_stock(product, order, order_item, @avoid_allocation)
      end
    else
      return unless product.product_forecasting.present?

      allocation_for_safe_stock(product, order, order_item, @avoid_allocation)
    end
    @allocation_check = (@avoid_allocation.all?(false) ? true : false)
  end

  def allocation_for_safe_stock(product, order, order_item, avoid_allocation)
    channel_type = order.channel_type
    if (product.forecasting.include? channel_type) && (product.forecasting[channel_type].include? 'product_units') && product.forecasting[channel_type]['product_units'].negative?
      avoid_allocation_by_safe_stock_based_on_product_units(order_item, channel_type, product, avoid_allocation)
    elsif (product.forecasting.include? channel_type) && (product.forecasting[channel_type].include? 'order_units') && product.forecasting[channel_type]['order_units'].negative?
      avoid_allocation_by_safe_stock_based_on_order_units(channel_type, order, avoid_allocation)
    end
  end

  def avoid_allocation_by_safe_stock_based_on_product_units(order_item, channel_type, product, avoid_allocation)
    product = Product.find(product.id)
    product_forecasting = product.forecasting
    type_number = product_forecasting[channel_type]['product_units'].abs
    difference = product.available_stock.to_i - order_item.ordered.to_i
    avoid_allocation.push(type_number <= difference)
  end

  def avoid_allocation_by_safe_stock_based_on_order_units(channel_type, order, avoid_allocation)
    return if order.channel_order_items.map(&:allocated).all?(true)

    order.channel_order_items.each do |item|
      next if item.allocated

      product = item.channel_product.product_mapping.product
      if product.product_type_single?
        product = Product.find(product.id)
        product_forecasting = product.forecasting
        type_number = product_forecasting[channel_type]['order_units'].abs
        deduction_unit = 1
        available_stock = product.available_stock / deduction_unit
        ordered_quantity = item.ordered * deduction_unit
        difference = available_stock - ordered_quantity
        avoid_allocation.push(type_number <= difference)
      else
        check = product.multipack_products.map { |m| m.child.forecasting[channel_type]['order_units'].negative? }
        next if check.any?(false)

        product.multipack_products.each do |multipack|
          child = multipack.child
          child = Product.find(child.id)
          product_forecasting = child.forecasting
          type_number = product_forecasting[channel_type]['order_units'].abs
          deduction_unit = multipack.quantity
          available_stock = child.available_stock / deduction_unit
          ordered_quantity = item.ordered * deduction_unit
          difference = available_stock - ordered_quantity
          avoid_allocation.push(type_number <= difference)
        end
      end
    end
  end
end
