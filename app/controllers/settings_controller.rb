class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_counts = { products_count: Product.count, users_count: User.count, categories_count: Category.count, seasons_count: Season.count }
  end

end
