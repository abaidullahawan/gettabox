# frozen_string_literal: true

# Getting new orders and creating
class OrderDispatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :refresh_token, only: %i[index all_order_data]
  before_action :check_status, only: %i[index fetch_response_orders]

  def index
    @all_orders = ChannelOrder.all
    @orders = @all_orders.order(created_at: :desc).page(params[:page]).per(params[:limit])
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
