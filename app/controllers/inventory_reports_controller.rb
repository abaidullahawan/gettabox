# frozen_string_literal: true

# Inventory Reports
class InventoryReportsController < ApplicationController
  include Reports

  def index
    @asc_desc = { 'asc': 'Ascending', 'desc': 'Descending' }
    @sale_channels = SystemUser.sales_channels.deep_dup
    @sale_channels['all_channels'] = 'All Channels'
    @sale_channels = @sale_channels.sort.to_h
    @suppliers = SystemUser.suppliers.map { |s| [s.name, s.id] }.to_h
    @suppliers['ALL_suppliers'] = 'All Suppliers'
    @suppliers = @suppliers.sort.to_h
    return unless params[:asc_desc].present?

    @date = date_from_to
    @inventory_products = filter_results(@date)
    @include_arrivals = params[:arrival].include? 'Include'
    @inventory_products_datum = Kaminari.paginate_array(@inventory_products.to_a).page(params[:page]).per(params[:limit])
    # @sales_unit = {}
    # @sales = {}
    # @inventory_orders.each do |order|
    #   order.channel_order_items.each do |product|
    #     product_id = product&.channel_product&.product_mapping&.product&.id
    #     @sales_unit[product_id] = calculate_sales_unit(product_id)
    #     @sales[product_id] = calculate_sales(product_id)
    #   end
    # end
    export_inventory_reports if params[:commit] == 'Export Button'
  end

  def export_inventory_reports
    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers
      @inventory_products&.each do |item|
        pending_arrival = 0
        product = item.last.first[:product]
        cost_price = item.last.pluck(:sales)
        quantity = item.last.pluck(:quantity)
        sales = cost_price.zip(quantity).map { |x, y| x.to_f * y }.sum
        number_of_days = @date.last.split('-').last.to_i - @date.first.split('-').last.to_i + 1
        weekly_sales = (sales.to_f / number_of_days) * 7
        product.system_users.last.purchase_orders.where(created_at: @date).each do |purchase_order|
          purchase_order.purchase_order_details.each do |detail|
            pending_arrival += detail.quantity.to_i - detail.missing.to_i - detail.demaged.to_i
          end
        end
        row = [
          product.id, product.title, product.sku, quantity.sum, sales.round(2), weekly_sales.round(2), product.total_stock.to_i,
          ((product.total_stock.to_i + (pending_arrival.present? ? pending_arrival : 0)) / (item.last.pluck(:quantity).sum.to_f / number_of_days)).round(0)
        ]
        row.insert(6, pending_arrival) if @include_arrivals == true
        csv << row
      end
    end
    send_data csv_data, filename: "inventory-reports-#{Date.today}.csv", disposition: :attachment
  end

  private

  # def calculate_sales_unit(id)
  #   count = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: :product]]).includes(
  #     channel_order_items: [channel_product: [product_mapping: :product]]
  #   ).where('products.id = ?', id).where(stage: 'completed').where(
  #     'channel_orders.updated_at': @date
  #   ).count
  #   date_from = @date.first.split('-').last.to_i
  #   date_to = @date.last.split('-').last.to_i
  #   @number_of_days = date_to - date_from + 1
  #   sales_unit = count / @number_of_days.to_f
  # end

  # def calculate_sales(id)
  #   sales = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: :product]]).includes(
  #     channel_order_items: [channel_product: [product_mapping: :product]]
  #   ).where('products.id = ?', id).where(stage: 'completed').where(
  #     'channel_orders.updated_at': @date
  #   )
  #   byebug
  #   sales_count = sales.count
  #   sales = sales.pluck(:cost_price).last.to_f
  #   sales = sales_count * sales
  #   return sales
  # end

  def calculate_all_channels(date)
    multiple_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .where('products.product_type': 'multiple')
                                    .where(created_at: date, 'system_users.id': params[:supplier])
                                    .order("channel_orders.created_at #{params[:asc_desc]}")
    single_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .where('products.product_type': 'single')
                                  .where(created_at: date, 'system_users.id': params[:supplier])
                                  .order("channel_orders.created_at #{params[:asc_desc]}")
    single_and_multi_products(multiple_products, single_products)
  end

  def calculate_all_suppliers(date)
    multiple_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .where('products.product_type': 'multiple')
                                    .where(created_at: date, channel_type: params[:channels])
                                    .order("channel_orders.created_at #{params[:asc_desc]}")
    single_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .where('products.product_type': 'single')
                                  .where(created_at: date, channel_type: params[:channels])
                                  .order("channel_orders.created_at #{params[:asc_desc]}")
    single_and_multi_products(multiple_products, single_products)
  end

  def calculate_all_channels_and_all_suppliers(date)
    multiple_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .where('products.product_type': 'multiple')
                                    .where(created_at: date).order("channel_orders.created_at #{params[:asc_desc]}")
    single_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .where('products.product_type': 'single')
                                  .where(created_at: date).order("channel_orders.created_at #{params[:asc_desc]}")
    single_and_multi_products(multiple_products, single_products)
  end

  def filter_when_none_selected(date)
    multiple_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                    .where('products.product_type': 'multiple')
                                    .uniq.where(created_at: date, channel_type: params[:channels], 'system_users.id': params[:supplier])
                                    .order("channel_orders.created_at #{params[:asc_desc]}")
    single_products = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .includes(channel_order_items: [channel_product: [product_mapping: [product: :system_users]]])
                                  .where('products.product_type': 'single')
                                  .uniq.where(created_at: date, channel_type: params[:channels], 'system_users.id': params[:supplier])
                                  .order("channel_orders.created_at #{params[:asc_desc]}")
    single_and_multi_products(multiple_products, single_products)
  end

  def single_and_multi_products(multiple_products, single_products)
    products = []
    multiple_products.each do |multiple_product|
      multiple_product.channel_order_items.each do |item|
        item.channel_product.product_mapping.product.multipack_products.each do |multi|
          product = multi.child
          products << { sku: product.sku, title: product.title, product: product, sales: product.cost_price, quantity: multi.quantity.to_i * item.ordered }
        end
      end
    end

    single_products.each do |single_product|
      single_product.channel_order_items.each do |item|
        product = item.channel_product.product_mapping.product
        products << { sku: product.sku, title: product.title, product: product, sales: product.cost_price, quantity: item.ordered.to_i }
      end
    end
    products.group_by { |d| d[:sku] }
  end

  def filter_results(date)
    if params[:channels] == 'All Channels' && params[:supplier] == 'All Suppliers'
      calculate_all_channels_and_all_suppliers(@date)
    elsif params['supplier'].eql? 'All Suppliers'
      calculate_all_suppliers(@date)
    elsif params['channels'].eql? 'All Channels'
      calculate_all_channels(@date)
    else
      filter_when_none_selected(date)
    end
  end

  def csv_headers
    headers = [
      'ID', 'Product Name', 'Product SKU', 'Sales Unit', 'Sales £', 'Weekly Sales', 'Stock', 'Cover(days)'
    ]
    headers.insert(6, 'Pending Arrival') if @include_arrivals == true
    headers
  end
end
