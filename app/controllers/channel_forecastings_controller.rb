# frozen_string_literal: true

# Channel Forcasting rules for products.
class ChannelForecastingsController < ApplicationController

  # GET /couriers or /couriers.json
  def index
    @q = ChannelForecasting.ransack(params[:q])
    @channel_rules = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    @supplier = SystemUser.where(user_type: 'supplier')
  end

  def show; end

  def new
    @forecasting = ChannelForecasting.new
  end

  def edit; end

  def create
    @forecasting = ChannelForecasting.new(forecasting_params)
    if @forecasting.save
      if  params[:channel_forecasting][:system_user_id].present?
        ChannelProduct.includes(product_mapping: [product: [product_suppliers: :system_user]]).where('system_user.id': params[:channel_forecasting][:system_user_id]).update_all(channel_forecasting_id: @forecasting.id)
      end
      flash[:notice] = 'Channel Forecasting was successfully created.'
    else
      flash[:alert] = @forecasting.errors.full_messages
    end
    redirect_to channel_forecastings_path
  end

  def buffer_rule
    @forecasting = ChannelForecasting.all
    @product = ChannelProduct.find(params[:id])
    # request.format = 'js'
    respond_to do |format|
      format.js { render 'products/show/buffer_rule' }
    end
  end

  def assign_buffer_rule
    ChannelProduct.find_by(id: params[:product_id]).update(channel_forecasting_id: params[:forecasting_rule])
    redirect_to request.referrer
  end

  def update

  end

  def destroy

  end

  private

  def forecasting_params
    params.require(:channel_forecasting).permit(:name, :filter_name, :filter_by, :action, :type_number, :units, :system_user_id, :comparison_number)
  end
end
