class ApplicationController < ActionController::Base
    include DashboardsHelper

    before_action :authenticate_user!


  def attributes_for_filter
    @attributes_for_filter = []
    controller_name.classify.constantize.reflect_on_all_associations.map(&:name).each do |x|
      x = x.to_s.singularize.constantize

      next if x.include? "image"

      @attributes_for_filter << x.column_names
    end
  end
end
