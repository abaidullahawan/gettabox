# frozen_string_literal: true

# User setting page for available features
class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_counts = { products_count: Product.count,
                      users_count: User.count,
                      categories_count: Category.count,
                      seasons_count: Season.count,
                      extra_field_count: ExtraFieldName.count,
                      email_count: EmailTemplate.count,
                      import_mapping: ImportMapping.count,
                      courier: Courier.count,
                      service: Service.count,
                      mail_service_rule: MailServiceRule.count,
                      export_mapping: ExportMapping.count,
                      customer: SystemUser.customers.count,
                      pick_and_pack: OrderBatch.count,
                      product_location_mapping: ProductLocation.count,
                      channel_forecastings: ChannelForecasting.count,
                      sellings: Selling.count,
                      customized_rules: AssignRule.where(save_later: true).count,
                      general_settings: GeneralSetting.count
                     }
  end
end
