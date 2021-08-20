class ApplicationController < ActionController::Base

  def index
    User.all
  end
end
