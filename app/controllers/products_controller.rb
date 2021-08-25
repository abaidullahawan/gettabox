class ProductsController < ApplicationController

  before_action :authenticate_user!
  before_action :find_product, only: [:edit, :update, :show, :destroy]
  # before_action :attributes_for_filter, only: [:index]

  def index
    @q = Product.ransack(params[:q])
    @products = @q.result(distinct: true)
  end

  def new
    @product = Product.new
    @product.barcodes.build
    @product.system_users.build
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to products_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to products_path
    else
      render 'edit'
    end
  end

  def show
  end

  def destroy
    @product.destroy

    redirect_to products_path
  end

  private

  def find_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.
    require(:product).
    permit( :sku,
            :title,
            :photo,
            :total_stock,
            :fake_stock,
            :pending_orders,
            :allocated_orders,
            :available_stock,
            :length,
            :width,
            :height,
            :weight,
            :pack_quantity,
            :cost_price,
            :gst,
            :vat,
            :hst,
            :pst,
            :qst,
            :minimum,
            :maximum,
            :optimal,
            barcodes_attributes:
            [ :id,
              :title,
              :_destroy
            ],
            system_users_attributes:
            [ :id,
              :sku,
              :_destroy
            ]
    )
  end

end