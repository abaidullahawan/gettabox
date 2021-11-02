# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  include DashboardsHelper

  before_action :authenticate_user!
  before_action :authentication_tokens

  def attributes_for_filter
    @attributes_for_filter = []
    controller_name.classify.constantize.reflect_on_all_associations.map(&:name).each do |x|
      x = x.to_s.singularize.constantize

      next if x.include? 'image'

      @attributes_for_filter << x.column_names
    end
  end

  def refresh_token
    @refresh_token = RefreshToken.last
    credential = Credential.find_by(grant_type: 'refresh_token')
    remainaing_time = @refresh_token.access_token_expiry.localtime > DateTime.now
    return if @refresh_token.present? && remainaing_time

    return generate_refresh_token(credential) if credential.present?

    flash[:alert] = 'Please contact your administration for process'
  end

  def generate_refresh_token(credential)
    result = RefreshTokenService.refresh_token_api(@refresh_token, credential)
    return update_refresh_token(result[:body]) if result[:status]

    flash[:alert] = (result['error_description']).to_s
  rescue StandardError
    flash[:alert] = 'Please contact your administration for process'
  end

  def update_refresh_token(result)
    @refresh_token.update(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds
    )
  end

  def authentication_tokens
    credential = Credential.find_by(grant_type: 'refresh_token')
    code = params['code']
    return unless code.present? && params['expires_in'].present?

    return generate_authentication_token(code, credential) if credential.present?

    flash[:alert] = 'Please contact your administration for process'
  end

  def generate_authentication_token(code, credential)
    result = RefreshTokenService.authentication_token_api(code, credential)
    return create_refresh_token(result[:body]) if result[:status]

    flash[:alert] = (result['error_description']).to_s
    redirect_to root_path
  rescue StandardError
    flash[:alert] = 'Please contact your administration for process'
  end

  def create_refresh_token(result)
    @refresh_token = RefreshToken.create(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds,
      refresh_token: result['refresh_token'],
      refresh_token_expiry: DateTime.now + result['refresh_token_expires_in'].to_i.seconds
    )
    flash[:notice] = 'Refresh token generated successfully!'
  end
end
