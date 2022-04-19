# frozen_string_literal: true

# Dispatch Reports
class DispatchReportsController < ApplicationController
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
      ).where(stage: 'completed').where(created_at: date)
    else
      channel_order_export = ChannelOrder.joins(
        channel_order_items: [channel_product: [product_mapping: :product]]
      ).includes(
        channel_order_items: [channel_product: [product_mapping: :product]]
      ).where(stage: 'completed').where(created_at: date, channel_type: params[:channels]&.downcase)
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
end
