# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :refresh_token, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]
  before_action :params_check, :completed_orders, :matched_sku, :no_sku, :unpaid_orders, :unmatched_product_orders, :unmatched_sku, :not_started_orders, only: %i[ index ]

  def index
    @q = ChannelOrder.search(params[:q])
    all_order_data if params[:orders_api].present?
  end

  def show; end

  def create; end

  def all_order_data
    if params[:amazon]
      OrdersAmzService.orders_amz
      create_amazon_orders
    else
      CreateChannelOrderResponseJob.perform_later
      flash[:notice] = 'CALL sent to eBay API'
      redirect_to order_dispatches_path
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

  def create_amazon_orders
    amazon_orders = ChannelResponseData.where(channel: 'amazon', api_call: 'getOrders', status: 'pending')
    amazon_orders.each do |amazon_order|
      amazon_order.response['payload']['Orders'].each do |order|
        channel_order_record = ChannelOrder.find_or_initialize_by(ebayorder_id: order['AmazonOrderId'],
                                                                  channel_type: 'amazon')

        channel_order_record.order_data = order
        channel_order_record.created_at = order['PurchaseDate']
        channel_order_record.order_status = order['OrderStatus']
        amount = order['OrderTotal'].nil? ? nil : order['OrderTotal']['Amount']
        channel_order_record.total_amount = amount
        address = "#{order['ShippingAddress']['PostalCode']} #{order['ShippingAddress']['City']} #{order['ShippingAddress']['CountryCode']}" if order['ShippingAddress'].present?
        channel_order_record.address = address
        channel_order_record.save
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
      @order_type = ['ebay', 'amazon']
    end
  end

  def unmatched_sku
    @unmatched_sku = []
    @all_orders = ChannelOrder.where(channel_type: @order_type) if @order_type.present?
    @all_orders = ChannelOrder.all if @order_type.nil?
    @unmatched_sku = @all_orders - @matched_sku - @no_sku - @completed - @un_matched_product_orders
    @unmatched_sku_sort = @unmatched_sku.sort_by(&:"created_at").reverse!
    @unmatched_sku_sort = Kaminari.paginate_array(@unmatched_sku).page(params[:unmatched_page]).per(5)
  end

  def completed_orders
    @completed = ChannelOrder.where('order_status in (?)', %i[FULFILLED Shipped]).where(channel_type: @order_type) if @order_type.present?
    @completed = ChannelOrder.where('order_status in (?)', %i[FULFILLED Shipped]) if @order_type.nil?
    @completed_orders = @completed.order(created_at: :desc).page(params[:completed_page]).per(params[:limit])
  end

  def matched_sku
    @matched_sku = []
    @product_data = ChannelProduct.where(status: 'mapped').pluck(:item_sku).compact
    @matched_sku = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': @product_data).where(channel_type: @order_type) if @order_type.present?
    @matched_sku = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': @product_data) if @order_type.nil?
    @matched_sku = @matched_sku.uniq
    @matched_sku = @matched_sku.sort_by(&:"created_at").reverse!
    @matched_sku = Kaminari.paginate_array(@matched_sku).page(params[:matched_page]).per(5)
  end

  def no_sku
    @no_sku = []
    @no_sku = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': nil).where(channel_type: @order_type) -@completed if @order_type.present?
    @no_sku = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': nil) - @completed if @order_type.nil?
    @orders = @no_sku.sort_by(&:"created_at").reverse!
    @orders = Kaminari.paginate_array(@no_sku).page(params[:orders_page]).per(5)
  end

  def unpaid_orders
    @unpaid_orders = ChannelOrder.where(payment_status: 'UNPAID').where(channel_type: @order_type) if @order_type.present?
    @unpaid_orders = ChannelOrder.where(payment_status: 'UNPAID') if @order_type.nil?
    @unpaid = @unpaid_orders.order(created_at: :desc).page(params[:unpaid_page]).per(params[:limit])
  end

  def not_started_orders
    @not_started = ChannelOrder.where(order_status: 'NOT_STARTED').where(channel_type: @order_type).order(created_at: :desc) - @no_sku - @unmatched_sku -@un_matched_product_orders if @order_type.present?
    @not_started = ChannelOrder.where(order_status: 'NOT_STARTED').order(created_at: :desc) - @no_sku - @unmatched_sku - @un_matched_product_orders if @order_type.nil?
    @not_started_orders = Kaminari.paginate_array(@not_started).page(params[:not_started_page]).per(25)
  end

  def unmatched_product_orders
    @unmatch_product_data = ChannelProduct.where(status: 'unmapped').pluck(:item_sku).compact
    @un_matched_product_orders = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': @unmatch_product_data).where(channel_type: @order_type).order(created_at: :desc) if @order_type.present?
    @un_matched_product_orders = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': @unmatch_product_data).order(created_at: :desc) if @order_type.nil?
    @un_matched_product_orders = @un_matched_product_orders.uniq - @completed
    @un_matched_product_order = Kaminari.paginate_array(@un_matched_product_orders).page(params[:unmatched_product_page]).per(5)
  end

end
