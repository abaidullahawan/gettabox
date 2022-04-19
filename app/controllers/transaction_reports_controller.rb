# frozen_string_literal: true

# Transaction Reports
class TransactionReportsController < ApplicationController
  def index
    @sale_channels = SystemUser.sales_channels.deep_dup
    @sale_channels['all_channels'] = 'All Channels'
    @sale_channels = @sale_channels.sort.to_h
    @date = date_from_to
    case params[:type]
    when 'Product'
      @channel_products_export, @channel_products = channel_order(@date)
    when 'Order'
      @channel_orders_export, @channel_orders = channel_order(@date)
    end

    export_reports_products if params[:commit] == 'Export Button' && params[:type] == 'Product'
    export_reports_orders if params[:commit] == 'Export Button' && params[:type] == 'Order'
  end

  def date_picker_from_to
    date = filter_date_range(params[:selectedValue])
    respond_to do |format|
      format.js
      format.json { render json: { start_date: date.first, end_date: date.last } }
    end
  end

  private

  def filter_date_range(date_range)
    case date_range
    when 'Today'
      Time.zone.today..Time.zone.today
    when 'This Week'
      Time.zone.today.beginning_of_week..Time.zone.today.end_of_week
    when 'Last Week'
      Time.zone.today.last_week.beginning_of_week..Time.zone.today.last_week.end_of_week
    when 'This Month'
      Time.zone.today.beginning_of_month..Time.zone.today.end_of_month
    when 'Last Month'
      Time.zone.today.last_month.beginning_of_month..Time.zone.today.last_month.end_of_month
    when 'This Year'
      Time.zone.today.beginning_of_year..Time.zone.today.end_of_year
    when 'Last Year'
      Time.zone.today.last_year.beginning_of_year..Time.zone.today.last_year.end_of_year
    end
  end

  def channel_order(date)
    if params[:channels].eql? 'All Channels'
      channel_order_export = ChannelOrder.joins(
        channel_order_items: [channel_product: [product_mapping: :product]]
      ).includes(
        channel_order_items: [channel_product: [product_mapping: :product]]
      ).where(stage: 'ready_to_dispatch').where(created_at: date)
    else
      channel_order_export = ChannelOrder.joins(
        channel_order_items: [channel_product: [product_mapping: :product]]
      ).includes(
        channel_order_items: [channel_product: [product_mapping: :product]]
      ).where(stage: 'ready_to_dispatch').where(created_at: date, channel_type: params[:channels]&.downcase)
    end
    channel_order = channel_order_export.page(params[:page]).per(params[:limit])
    [channel_order_export, channel_order]
  end

  def date_from_to
    return unless params[:date_from].present? && params[:date_to].present?

    date_from = params[:date_from]
    date_to = params[:date_to]
    date_from..date_to
  end

  def export_reports_products
    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers
      @channel_products_export.each do |order|
        order.channel_order_items.each do |product|
          if product.channel_product&.product_mapping&.product&.product_type_single?
            csv << [
              order.channel_type, order.buyer_name, product.channel_order_id, order.order_id,
              order.created_at.strftime('%m/%d/%Y'), product.channel_product&.product_mapping&.product&.title,
              product.channel_product&.product_mapping&.product&.sku, product&.ordered.to_i, order.total_amount,
              product.channel_product&.product_mapping&.product&.cost_price.to_f,
              order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
            ]
          else
            total_cost_price = 0
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              total_cost_price += record.child&.cost_price.to_f * record.quantity * product.ordered.to_i
              cost_price = record.child&.cost_price.to_f * record.quantity * product.ordered.to_i
              distributed_cost_price = (order.total_amount / total_cost_price) * cost_price
              csv << [
                order.channel_type, order.buyer_name, product.channel_order_id, order.order_id,
                order.created_at.strftime('%m/%d/%Y'), record&.child&.title, record&.child&.sku,
                record.quantity * product.ordered.to_i, distributed_cost_price.round(2),
                record.child&.cost_price.to_f * record.quantity * product.ordered.to_i,
                order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
              ]
            end
          end
        end
      end
    end
    send_data csv_data, filename: "transaction-reports-#{Date.today}.csv", disposition: :attachment
  end

  def export_reports_orders
    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers
      @channel_orders_export.each do |order|
        order.channel_order_items.each do |product|
          if product.channel_product&.product_mapping&.product&.product_type_single?
            csv << [
              order.channel_type, order.buyer_name, product.channel_order_id, order.order_id,
              order.created_at.strftime('%m/%d/%Y'), product&.channel_product&.product_mapping&.product&.title,
              product.channel_product&.product_mapping&.product&.sku,
              product&.ordered.to_i, order.total_amount,
              product.channel_product&.product_mapping&.product&.cost_price.to_f,
              order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
            ]
          else
            title = []
            sku = []
            quantity = []
            total_cost_price = 0
            product.channel_product&.product_mapping&.product&.multipack_products&.each do |record|
              title.push(record&.child&.title)
              sku.push(record&.child&.sku)
              qty = record.quantity * product.ordered.to_i
              quantity.push(qty)
              cost_price = record.child&.cost_price.to_f
              total_cost_price += qty * cost_price
            end
            csv << [
              order.channel_type, order.buyer_name, product.channel_order_id, order.order_id,
              order.created_at.strftime('%m/%d/%Y'), title.join(', '), sku.join(', '), quantity.join(', '), order.total_amount, total_cost_price,
              order.channel_type_amazon? ? order['order_data']['BuyerInfo']['BuyerEmail'] : order['order_data']['fulfillmentStartInstructions'].first['shippingStep']['shipTo']['email']
            ]
          end
        end
      end
    end
    send_data csv_data, filename: "transaction-reports-#{Date.today}.csv", disposition: :attachment
  end

  def csv_headers
    ['Sales Channel', 'Customer', 'Order ID', 'Channel Order ID', 'Order Date(order paid)',
     'Product', 'SKU', 'Quantity', 'Sale Price (GBP) Net', 'Cost Price', 'Email']
  end
end