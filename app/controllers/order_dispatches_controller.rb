# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :refresh_token, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]

  def index
    @no_sku = []
    @matched_sku = []
    @unmatched_sku = []
    @all_orders = ChannelOrder.all
    @not_started = ChannelOrder.where(order_status: 'NOT_STARTED')
    @not_started_orders = @not_started.order(created_at: :desc).page(params[:not_started_page]).per(params[:limit])
    @unpaid_orders = ChannelOrder.where(payment_status: 'UNPAID')
    @unpaid = @unpaid_orders.order(created_at: :desc).page(params[:unpaid_page]).per(params[:limit])
    @completed = ChannelOrder.where(order_status: 'FULFILLED')
    @completed_orders = @completed.order(created_at: :desc).page(params[:completed_page]).per(params[:limit])
    @product_data = ChannelProduct.pluck(:item_sku).compact
    @no_sku = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': nil)
    @no_sku_count = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': nil).count
    @orders = @no_sku.order(created_at: :desc).page(params[:orders_page]).per(5)
    @matched_sku = ChannelOrder.joins(:channel_order_items).where('channel_order_items.sku': @product_data)
    @matched_sku = @matched_sku.uniq
    @unmatched_sku = @all_orders - @matched_sku - @no_sku
    @matched_sku = @matched_sku.sort_by(&:"created_at").reverse!
    @matched_sku = Kaminari.paginate_array(@matched_sku).page(params[:matched_page]).per(5)
    @unmatched_sku_sort = @unmatched_sku.sort_by(&:"created_at").reverse!
    @unmatched_sku_sort = Kaminari.paginate_array(@unmatched_sku).page(params[:unmatched_page]).per(5)
    all_order_data if params[:all_product_data].present?
  end

  def show; end

  def create; end

  def all_order_data
    CreateChannelOrderResponseJob.perform_later
    flash[:notice] = 'CALL sent to eBay API'
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
end
