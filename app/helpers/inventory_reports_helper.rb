# frozen_string_literal: true

module InventoryReportsHelper # :nodoc:
  def weekly_sales(id)
    ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: :product]]).includes(
      channel_order_items: [channel_product: [product_mapping: :product]]
    ).where('products.id = ?', id).where(stage: 'completed').where(
      'DATE(channel_orders.updated_at) >= ?', Time.zone.now.beginning_of_week
    ).count
  end
end
