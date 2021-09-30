module NewProduct
  extend ActiveSupport::Concern

  def new_product
    @product = Product.new
    @product.barcodes.build
    @product.product_suppliers.build
    @product.multipack_products.build
    @product.extra_field_names.build
    @product.build_extra_field_value
    @pros = Product.all
  end

  def product_load_resources
    @single_products = Product.where(product_type: 'single').map{|v| v.serializable_hash(only: [:id, :title]) }
    @system_users = SystemUser.all.map{|v| v.serializable_hash(only: [:id, :name]) }
    @categories = Category.all.map{|v| v.serializable_hash(only: [:id, :title]) }
    @seasons = Season.all.map{|v| v.serializable_hash(only: [:id, :name]) }
  end

  def first_or_create_category
    @category_name = params[:category_name]
    @s_category = Category.where("title ILIKE ?", "#{@category_name}").first_or_create(title: "#{@category_name}")
    @product.category_id = @s_category.id
  end
end