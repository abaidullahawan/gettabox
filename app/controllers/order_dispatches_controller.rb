# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :refresh_token, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]
  before_action :ransack_params, :params_check, :completed_orders, :matched_sku, :no_sku, :unpaid_orders, :unmatched_product_orders,
                :unmatched_sku, :not_started_orders, only: %i[index]

  def index
    @q = ChannelOrder.ransack(params[:q])
    all_order_data if params[:orders_api].present?
  end

  def show; end

  def create; end

  def all_order_data
    if params[:amazon]
      AmazonService.amazon_order_api
      create_amazon_orders
    else
      CreateChannelOrderResponseJob.perform_later
      flash[:notice] = 'CALL sent to eBay API'
    end
    redirect_to order_dispatches_path
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

  def create_amazon_orders
    amazon_orders = ChannelResponseData.where(channel: 'amazon', api_call: 'getOrders', status: 'pending')
    amazon_orders.each do |amazon_order|
      amazon_order.response['payload']['Orders'].each do |order|
        channel_order = ChannelOrder.find_or_initialize_by(ebayorder_id: order['AmazonOrderId'],
                                                           channel_type: 'amazon')
        channel_order.order_data = order
        channel_order.created_at = order['PurchaseDate']
        channel_order.order_status = order['OrderStatus']
        amount = order['OrderTotal'].nil? ? nil : order['OrderTotal']['Amount']
        channel_order.total_amount = amount
        address = "#{order['ShippingAddress']['PostalCode']} #{order['ShippingAddress']['City']} #{order['ShippingAddress']['CountryCode']}" if order['ShippingAddress'].present?
        channel_order.address = address
        channel_order.save
        result = AmazonService.amazon_product_api(channel_order.ebayorder_id)
        update_channel_order(result[:body], channel_order.id) if result[:status]
      end
      amazon_order.update(status: 'executed')
    end
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
    @unpaid_orders = @q.where(payment_status: 'UNPAID').where(channel_type: @order_type)
    @unpaid = @unpaid_orders.order(created_at: :desc).page(params[:unpaid_page]).per(params[:limit])
  end

  def not_started_orders
    @not_started = @q.where(order_status: 'NOT_STARTED').where(channel_type: @order_type).order(created_at: :desc) - @no_sku - @unmatched_sku -@un_matched_product_orders
    @not_started_orders = Kaminari.paginate_array(@not_started).page(params[:not_started_page]).per(25)
  end

  def unmatched_product_orders
    @unmatch_product_data = ChannelProduct.where(status: 'unmapped').pluck(:item_sku).compact
    @un_matched_product_orders = @q.joins(:channel_order_items).where('channel_order_items.sku': @unmatch_product_data).where(channel_type: @order_type).order(created_at: :desc)
    @un_matched_product_orders = @un_matched_product_orders.uniq - @completed
    @un_matched_product_order = Kaminari.paginate_array(@un_matched_product_orders).page(params[:unmatched_product_page]).per(5)
  end

  def update_channel_order(result, channel_order_id)
    # result['payload']['OrderItems'].each do |item|
    #   ChannelOrderItem.create(
    #     channel_order_id: channel_order_id,
    #     line_item_id: item['OrderItemId'],
    #     sku: item['SellerSKU'],
    #     item_data: item
    #   )
    # end
    result['payload']['OrderItems'].each do |item|
      channel_item = ChannelOrderItem.find_or_initialize_by(
        channel_order_id: channel_order_id,
        line_item_id: item['OrderItemId']
      )
      channel_item.sku = item['SellerSKU']
      channel_item.item_data = item
      channel_item.save
    end
  end
end
