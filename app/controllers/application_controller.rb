class ApplicationController < ActionController::Base
    include DashboardsHelper

    before_action :authenticate_user!
end
