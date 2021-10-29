# frozen_string_literal: true

class AuthController < ApplicationController # :nodoc:
  before_action :authenticate_user!

  def signup; end

  def signin; end

  def forgot_password; end
end
