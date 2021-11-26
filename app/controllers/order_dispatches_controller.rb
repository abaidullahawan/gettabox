# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  include NewProduct
  before_action :authenticate_user!
  # before_action :refresh_token, :refresh_token_amazon, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]
  before_action :ransack_params, :params_check, :completed_orders, :matched_sku, :no_sku, :unpaid_orders, :unmatched_product_orders,
                :unmatched_sku, :not_started_orders, only: %i[index]
  before_action :new_product, :product_load_resources, :first_or_create_category, only: %i[index]

  def index
    @q = ChannelOrder.ransack(params[:q])
    export_csv(@q.result) if params[:export_csv].present?
    respond_to do |format|
      format.html
      format.csv
    end
    all_order_data if params[:orders_api].present?
    @product = Product.new
    @matching_products = {}
    @un_matched_product_order.each do |order|
      order.channel_order_items.each do |item|
        matching = Product.find_by('sku LIKE ?', "%#{item.sku}%")
        @matching_products[item.id] = matching if matching.present?
      end
    end
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
    redirect_to order_dispatches_path
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
    redirect_to order_dispatches_path
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

  def params_check
    if params[:product_mapping].eql? 'Amazon Orders'
      @order_type = 'amazon'
    elsif params[:product_mapping].eql? 'Ebay Orders'
      @order_type = ['ebay']
    else
      @order_type = %w[ebay amazon]
    end
  end

  def ransack_params
    @q = ChannelOrder.ransack(params[:q])
    @q = @q.result
  end

  def unmatched_sku
    @unmatched_sku = []
    @all_orders = @q.where(channel_type: @order_type)
    @unmatched_sku = @all_orders - @matched_sku - @no_sku - @completed - @un_matched_product_orders
    @unmatched_sku_sort = @unmatched_sku.sort_by(&:created_at).reverse!
    @unmatched_sku_sort = Kaminari.paginate_array(@unmatched_sku).page(params[:unmatched_page]).per(5)
  end

  def completed_orders
    @completed = @q.where('order_status in (?)', %i[FULFILLED Shipped]).where(channel_type: @order_type)
    @completed_orders = @completed.order(created_at: :desc).page(params[:completed_page]).per(params[:limit])
  end

  def matched_sku
    @matched_sku = []
    @product_data = ChannelProduct.where(status: 'mapped').pluck(:item_sku).compact
    @matched_sku = @q.joins(:channel_order_items).where('channel_order_items.sku': @product_data).where(channel_type: @order_type)
    @matched_sku = @matched_sku.uniq
    @matched_sku = @matched_sku.sort_by(&:created_at).reverse!
    @matched_sku = Kaminari.paginate_array(@matched_sku).page(params[:matched_page]).per(5)
  end

  def no_sku
    @no_sku = []
    @no_sku = @q.joins(:channel_order_items).where('channel_order_items.sku': nil).where(channel_type: @order_type) -@completed
    @orders = @no_sku.sort_by(&:created_at).reverse!
    @orders = Kaminari.paginate_array(@no_sku).page(params[:orders_page]).per(5)
  end

  def unpaid_orders
    @unpaid_orders = @q.where('payment_status = ? OR order_status = ?', 'UNPAID', 'Pending').where(channel_type: @order_type)
    @unpaid = @unpaid_orders.order(created_at: :desc).page(params[:unpaid_page]).per(params[:limit])
  end

  def not_started_orders
    @not_started = @q.where(order_status: 'NOT_STARTED').where(channel_type: @order_type).order(created_at: :desc) - @no_sku -@un_matched_product_orders
    @not_started_orders = Kaminari.paginate_array(@not_started).page(params[:not_started_page]).per(25)
  end

  def unmatched_product_orders
    @unmatch_product_data = ChannelProduct.where(status: 'unmapped').pluck(:item_sku).compact
    @un_matched_product_orders = @q.joins(:channel_order_items).where('channel_order_items.sku': @unmatch_product_data).where(channel_type: @order_type).order(created_at: :desc)
    @un_matched_product_orders = @un_matched_product_orders.uniq - @completed
    @un_matched_product_order = Kaminari.paginate_array(@un_matched_product_orders).page(params[:unmatched_product_page]).per(5)
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
end
