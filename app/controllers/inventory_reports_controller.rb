# frozen_string_literal: true

# Inventory Reports
class InventoryReportsController < ApplicationController
  def index
    @asc_desc = { 'asc': 'Ascending', 'desc': 'Descending' }
    @sale_channels = SystemUser.sales_channels.deep_dup
    @sale_channels['all_channels'] = 'All Channels'
    @sale_channels = @sale_channels.sort.to_h
    @suppliers = SystemUser.suppliers.map { |s| [s.name, s.id] }.to_h
    @suppliers['ALL_suppliers'] = 'All Suppliers'
    @suppliers = @suppliers.sort.to_h
    return unless params['/inventory_reports'].present?

    if params['/inventory_reports']['date_from'].present? && params['/inventory_reports']['date_to'].present?
      date_from = params['/inventory_reports']['date_from']
      date_to = params['/inventory_reports']['date_to']
      @date = date_from..date_to
    end
    if params['/inventory_reports']['channels'] == 'All Channels' && params['/inventory_reports']['supplier'] == 'All Suppliers'
      @inventory_products = Product.joins(:system_users).includes(:system_users).where(
        'products.created_at': @date, product_type: 'single'
      ).order("products.created_at #{params['/inventory_reports']['asc_desc']}").page(params[:page]).per(params[:limit])
    elsif params['/inventory_reports']['supplier'] == 'All Suppliers'
      @inventory_products = Product.joins(:system_users).includes(:system_users).where(
        'products.created_at': @date, product_type: 'single', 'system_users.sales_channel': params['/inventory_reports']['channels']
      ).order("products.created_at #{params['/inventory_reports']['asc_desc']}").page(params[:page]).per(params[:limit])
    elsif params['/inventory_reports']['channels'] == 'All Channels'
      @inventory_products = Product.joins(:system_users).includes(:system_users).where(
        'products.created_at': @date, product_type: 'single', 'system_users.id': params['/inventory_reports']['supplier']
      ).order("products.created_at #{params['/inventory_reports']['asc_desc']}").page(params[:page]).per(params[:limit])
    else
      @inventory_products = Product.joins(:system_users).includes(:system_users).where(
        'products.created_at': @date, product_type: 'single', 'system_users.sales_channel': params['/inventory_reports']['channels'],
        'system_users.id': params['/inventory_reports']['supplier']
      ).order("products.created_at #{params['/inventory_reports']['asc_desc']}").page(params[:page]).per(params[:limit])
    end
    @sales_unit = {}
    @sales = {}
    @inventory_products.each do |product|
      @sales_unit[product.id] = calculate_sales_unit(product.id)
      @sales[product.id] = calculate_sales(product.id)
    end
    export_reports(@inventory_products) if params[:commit].eql? 'Export Button'
  end

  def date_picker_from_to
    date = filter_date_range(params[:selectedValue])
    respond_to do |format|
      format.js
      format.json { render json: { start_date: date.first, end_date: date.last } }
    end
  end

  def export_reports(products)
    headers = ['ID', 'Product SKU', 'Sales Unit', 'Sales £', 'Weekly Sales', 'Purchased Qty', 'Stock', 'Cover(days)']
    csv_data = CSV.generate(headers: true) do |csv|
      csv << headers
    # @csv = CSV.generqate
    # @csv << attributes
    # products.each do |product|
    #   data = []
    #   data.push(product.id, product.sku)
    #   @csv << data
    # end
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

  def calculate_sales_unit(id)
    count = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: :product]]).includes(
      channel_order_items: [channel_product: [product_mapping: :product]]
    ).where('products.id = ?', id).where(stage: 'completed').where(
      'channel_orders.updated_at': @date
    ).count
    date_from = @date.first.split('-').last.to_i
    date_to = @date.last.split('-').last.to_i
    @number_of_days = date_to - date_from + 1
    sales_unit = count / @number_of_days.to_f
  end

  def calculate_sales(id)
    sales = ChannelOrder.joins(channel_order_items: [channel_product: [product_mapping: :product]]).includes(
      channel_order_items: [channel_product: [product_mapping: :product]]
    ).where('products.id = ?', id).where(stage: 'completed').where(
      'channel_orders.updated_at': @date
    )
    sales_count = sales.count
    sales = sales.pluck(:total_amount).last.to_f
    sales = sales_count * sales
    return sales
  end
end
