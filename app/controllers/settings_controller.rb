class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_counts = { products_count: Product.count, users_count: User.count, categories_count: Category.count,
                      seasons_count: Season.count, extra_field_count: ExtraFieldName.count, email_count: EmailTemplate.count }
  end
end
