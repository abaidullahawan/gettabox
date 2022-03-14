# frozen_string_literal: true

# seasons are for products
class SellingsController < ApplicationController

  before_action :set_selling, only: %i[show edit update destroy]

  def index
    @selling = Selling.last
  end

  def show; end

  def new; end

  def edit; end

  def ebay_selling
    @selling = Selling.last
  end

  def create
    @selling = Selling.new(selling_params)
    if @selling.save
      flash[:notice] = 'Selling created successfully.'
    else
      flash.now[:notice] = 'Selling not created.'
    end
    redirect_to request.referrer
  end

  def update
    if @selling.update(selling_params)
      flash[:notice] = 'Selling updated successfully.'
    else
      flash.now[:notice] = 'Selling not created.'
    end
    redirect_to sellings_path
  end

  def destroy
    return unless @selling.destroy

    flash[:notice] = 'Selling deleted successfully.'
    redirect_to sellings_path
  end

  private

  def selling_params
    params.require(:selling).permit(:name, :quantity)
  end

  def set_selling
    @selling = Selling.find(params[:id])
  end

end
