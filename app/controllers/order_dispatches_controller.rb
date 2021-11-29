# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  include NewProduct
  before_action :authenticate_user!
  # before_action :refresh_token, :refresh_token_amazon, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]
  before_action :ransack_params, :load_counts, :completed_orders, :no_sku, :unpaid_orders, :unmatched_product_orders,
                :unmatched_sku, :not_started_orders, only: %i[index]
  before_action :new_product, :product_load_resources, :first_or_create_category, only: %i[index]

  def index
    export_csv(@channel_orders) if params[:export_csv].present?
    respond_to do |format|
      format.html
      format.csv
    end
    all_order_data if params[:orders_api].present?
    @mail_service_rule = MailServiceRule.new
  end

  def show; end

  def create; end

  def all_order_data
    if params[:amazon]
      AmazonOrderJob.perform_later
      flash[:notice] = 'Amazon order job created!'
    else
      CreateChannelOrderResponseJob.perform_later
      flash[:notice] = 'CALL sent to eBay API'
    end
    redirect_to order_dispatches_path(order_filter: 'unprocessed')
  end

  def export_csv(orders)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data csv_export(orders), filename: "products-#{Date.today}.csv" }
    end
  end

  def fetch_response_orders
    if @status.zero?
      flash[:notice] = 'Please CALL eBay Orders.'
    else
      CreateChannelOrderJob.perform_later
      flash[:notice] = 'eBay Orders are saving . . .'
    end
    redirect_to order_dispatches_path(order_filter: 'unprocessed')
  end

  private

  def order_mapping_params; end

  def check_status
    @response_status = ChannelResponseData.all.pluck(:status)
    @status = 1
    @response_status.each do |response_status|
      @status = 0 if (response_status == 'error') || (response_status == 'not available')
    end
    @status = 3 if @response_status == []
  end

  # def params_check
  #   if params[:product_mapping].eql? 'Amazon Orders'
  #     @order_type = 'amazon'
  #   elsif params[:product_mapping].eql? 'Ebay Orders'
  #     @order_type = ['ebay']
  #   else
  #     @order_type = %w[ebay amazon]
  #   end
  # end

  def ransack_params
    @q = ChannelOrder.ransack(params[:q])
    @channel_orders = @q.result
    @channel_types = ChannelOrder.channel_types
  end

  def unmatched_sku
    return unless params[:order_filter].eql? 'unprocessed'

    # @unmatched_sku = []
    @unmatched_sku = @channel_orders.joins(:channel_order_items)
                                    .where.not('channel_order_items.sku': [nil, @data])
                                    .where.not(order_status: %w[FULFILLED Shipped Pending])
                                    .order(created_at: :desc).distinct
                                    .page(params[:unmatched_page]).per(5)
    @matching_products = {}
    @un_matched_product_order.each do |order|
      order.channel_order_items.each do |item|
        matching = Product.find_by('sku LIKE ?', "%#{item.sku}%")
        @matching_products[item.id] = matching if matching.present?
      end
    end
  end

  def completed_orders
    return unless params[:order_filter].eql? 'completed'

    @completed = @channel_orders.where('order_status in (?)', %w[FULFILLED Shipped]).distinct
    @completed_orders = @completed.order(created_at: :desc).page(params[:completed_page]).per(params[:limit])
  end

  def no_sku
    return unless params[:order_filter].eql? 'issue'

    @issue_orders = @channel_orders.joins(:channel_order_items).where('channel_order_items.sku': nil)
                                   .where.not(order_status: %w[FULFILLED Shipped Pending])
                                   .order(created_at: :desc).distinct
                                   .page(params[:orders_page]).per(5)
  end

  def unpaid_orders
    return unless params[:order_filter].eql? 'unpaid'

    @unpaid_orders = @channel_orders.where(payment_status: 'UNPAID').or(@channel_orders.where(order_status: 'Pending')).distinct
    @unpaid = @unpaid_orders.order(created_at: :desc).page(params[:unpaid_page]).per(params[:limit])
  end

  def not_started_orders
    return unless params[:order_filter].eql? 'ready'

    @not_started_orders = @channel_orders.joins(:channel_order_items).where(order_status: 'NOT_STARTED')
                                         .where.not('channel_order_items.sku': [nil, @unmatch_product_data]).distinct
                                         .order(created_at: :desc).page(params[:not_started_page]).per(25)
  end

  def unmatched_product_orders
    return unless params[:order_filter].eql? 'unprocessed'

    @un_matched_product_order = @channel_orders.joins(:channel_order_items)
                                               .where('channel_order_items.sku': @unmatch_product_data)
                                               .where.not(order_status: %w[FULFILLED Shipped Pending])
                                               .order(created_at: :desc).distinct
                                               .page(params[:unmatched_product_page]).per(5)
  end

  def csv_export(orders)
    attributes = ChannelOrder.column_names.excluding('created_at', 'updated_at')
    CSV.generate(headers: true) do |csv|
      csv << attributes
      orders.each do |channel_order|
        row = channel_order.attributes.values_at(*attributes)
        csv << row
      end
    end
  end

  def load_counts
    @total_products_count = ChannelProduct.count
    @issue_products_count = ChannelProduct.where(item_sku: nil).count
    @unmatch_product_data = ChannelProduct.where(status: 'unmapped').pluck(:item_sku).compact
    @product_data = ChannelProduct.where(status: 'mapped').pluck(:item_sku).compact
    @data = ChannelProduct.pluck(:item_sku).compact
    @today_orders = @channel_orders.where('Date(created_at) = ?', Date.today).distinct.count
    @issue_orders_count = @channel_orders.joins(:channel_order_items).where('channel_order_items.sku': nil)
                                         .where.not(order_status: %w[FULFILLED Shipped]).distinct.count
    @unpaid_orders_count = @channel_orders.where(payment_status: 'UNPAID')
                                          .or(@channel_orders.where(order_status: 'Pending')).distinct.count
    @not_started_count = @channel_orders.joins(:channel_order_items).where(order_status: 'NOT_STARTED')
                                        .where.not('channel_order_items.sku': [nil, @unmatch_product_data]).distinct.count
    @completed_count = @channel_orders.where('order_status in (?)', %i[FULFILLED Shipped]).distinct.count
    @un_matched_orders_count = @channel_orders.joins(:channel_order_items)
                                              .where('channel_order_items.sku': @unmatch_product_data)
                                              .where.not(order_status: %w[FULFILLED Shipped Pending]).distinct.count
    @unmatched_sku_count = @channel_orders.joins(:channel_order_items)
                                          .where.not('channel_order_items.sku': @data)
                                          .where.not(order_status: %w[FULFILLED Shipped Pending]).distinct.count
  end
end
