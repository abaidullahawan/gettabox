# frozen_string_literal: true

# Channel Forcasting rules for products.
class ChannelForecastingsController < ApplicationController

  before_action :set_channel_forecastings, only: %i[show edit update destroy]

  # GET /couriers or /couriers.json
  def index
    @q = ProductForecasting.ransack(params[:q])
    @channel_rules = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    @supplier = SystemUser.where(user_type: 'supplier')
    @forecasting = ProductForecasting.new
    @forecasting.channel_forecastings.build
  end

  def show; end

  def new
    @forecasting = ProductForecasting.new
  end

  def edit; end

  def create
    @forecasting = ProductForecasting.new(forecasting_params)
    if @forecasting.save
      flash[:notice] = 'Channel Forecasting was successfully created.'
    else
      flash[:alert] = @forecasting.errors.full_messages
    end
    redirect_to channel_forecastings_path
  end

  # def create
  #   @forecasting = ChannelForecasting.new(forecasting_params)
  #   filter = { 'contains' => 'LIKE', 'does_not_contain' => 'NOT LIKE', 'start_with' => 'LIKE', 'end_with' => 'LIKE' }
  #   compare_with = params[:channel_forecasting][:comparison_number]
  #   filter_with = { 'contains' => "%#{compare_with}%", 'does_not_contain' => "%#{compare_with}%",
  #                   'start_with' => "#{compare_with}%", 'end_with' => "%#{compare_with}" }
  #   if @forecasting.save
  #     if params[:channel_forecasting][:system_user_id].present?
  #       ChannelProduct.includes(product_mapping: [product: [product_suppliers: :system_user]])
  #                     .where('system_user.id': params[:channel_forecasting][:system_user_id])
  #                     .update_all(channel_forecasting_id: @forecasting.id, customize: nil)
  #     end
  #     case params[:channel_forecasting][:filter_name]
  #     when 'product_sku'
  #       ChannelProduct.joins(product_mapping: :product).includes(product_mapping: :product)
  #       .where(
  #         "products.sku #{filter[params[:channel_forecasting][:filter_by]]} ?",
  #          filter_with[params[:channel_forecasting][:filter_by]]
  #       ).update_all(channel_forecasting_id: @forecasting.id, customize: nil)
  #     when 'channel'
  #       ChannelProduct.where(channel_type: params[:channel_forecasting][:filter_by]).update_all(channel_forecasting_id: @forecasting.id, customize: nil)
  #     end
  #     flash[:notice] = 'Channel Forecasting was successfully created.'
  #   else
  #     flash[:alert] = @forecasting.errors.full_messages
  #   end
  #   redirect_to channel_forecastings_path
  # end

  def buffer_rule
    @forecasting = ChannelForecasting.all
    @product = ChannelProduct.find(params[:id])
    respond_to do |format|
      format.js { render 'products/show/buffer_rule' }
    end
  end

  def assign_buffer_rule
    ChannelProduct.find_by(id: params[:product_id]).update(channel_forecasting_id: params[:forecasting_rule], customize: true)
    redirect_to request.referrer
  end

  def update
    if @channel_forecasting.update(forecasting_params)
      update_channel_forecasting_for_product
      flash[:notice] = 'Channel Forecasting Rule was successfully updated.'
      redirect_to channel_forecastings_path
    else
      flash.now[:alert] = @channel_forecasting.errors.full_messages
      render :show
    end
  end

  def destroy
    if @channel_forecasting.destroy
      flash[:notice] = 'Channel Forecasting Rule was successfully deleted.'
      ChannelProduct.where(channel_forecasting_id: @channel_forecasting.id).update_all(channel_forecasting_id: nil, customize: nil)
      redirect_to channel_forecastings_path
    else
      flash.now[:alert] = @channel_forecasting.errors.full_messages
      render channel_forecastings_path
    end
  end

  private

  def set_channel_forecastings
    @channel_forecasting = ProductForecasting.find(params[:id])
    @supplier = SystemUser.where(user_type: 'supplier')
  end

  def forecasting_params
    params.require(:product_forecasting)
          .permit(:name, channel_forecastings_attributes:
            %i[id filter_name filter_by action type_number units _destroy]
          )
  end

  def update_channel_forecasting_for_product
    forecastings = {}
    channel_forecastings = @channel_forecasting.channel_forecastings
    channel_forecastings.each { |f| forecastings[f.filter_by] = { f.units => f.type_number * (f.action_anticipate_by? ? 1 : -1) } }
    products = @channel_forecasting.products
    products.update_all(forecasting: forecastings)
  end
end
