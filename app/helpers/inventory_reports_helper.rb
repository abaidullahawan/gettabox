# frozen_string_literal: true

module InventoryReportsHelper # :nodoc:
  def weekly_sales(id)
    ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: :product]]).includes(
      channel_order_items: [channel_product: [product_mapping: :product]]
    ).where('products.id = ?', id).where(stage: 'completed').where(
      'DATE(channel_orders.updated_at) >= ?', Time.zone.now.beginning_of_week
    ).count
  end

  def pending_arrival(product)
    pending_arrival = 0
    product.system_users.last.purchase_orders.each do |purchase_order|
      purchase_order.purchase_order_details.each do |detail|
        pending_arrival += detail.quantity.to_i - detail.missing.to_i
      end
    end
  end
end
