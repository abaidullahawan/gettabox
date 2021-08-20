class HomeController < ActionController::Base

  def index
    User.all
  end
end
