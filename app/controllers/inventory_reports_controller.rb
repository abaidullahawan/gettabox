# frozen_string_literal: true

# Inventory Reports
class InventoryReportsController < ApplicationController

  def index
    @asc_desc = { 'asc': 'Ascending', 'desc': 'Descending' }
    return unless params['/inventory_reports'].present?

    if params['/inventory_reports']['date_from'].present? && params['/inventory_reports']['date_to'].present?
      date_from = params['/inventory_reports']['date_from']
      date_to = params['/inventory_reports']['date_to']
      @date = date_from..date_to
    else
      @date = filter_date_range(params['/inventory_reports']['date_range'])
    end
    @inventory_products = Product.joins(:system_users).includes(:system_users).where(
      created_at: @date, 'system_users.sales_channel': params['/inventory_reports']['channels'],
      'system_users.id': params['/inventory_reports']['supplier']
    ).order("products.created_at #{params['/inventory_reports']['asc_desc']}").page(params[:page]).per(params[:limit])
  end

  private

  def filter_date_range(date_range)
    case date_range
    when 'Today'
      Date.today.beginning_of_day..Date.today.end_of_day
    when 'This Week'
      Date.today.beginning_of_week..Date.today.end_of_week
    when 'Last Week'
      Date.today.last_week.beginning_of_week..Date.today.last_week.end_of_week
    when 'This Month'
      Date.today.beginning_of_month..Date.today.end_of_month
    when 'Last Month'
      Date.today.last_month.beginning_of_month..Date.today.last_month.end_of_month
    when 'This Year'
      Date.today.beginning_of_year..Date.today.end_of_year
    when 'Last Year'
      Date.today.last_year.beginning_of_year..Date.today.last_year.end_of_year
    end
  end
end
