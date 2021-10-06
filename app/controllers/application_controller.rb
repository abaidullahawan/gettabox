class ApplicationController < ActionController::Base
    include DashboardsHelper

    before_action :authenticate_user!
    before_action :authentication_tokens


  def attributes_for_filter
    @attributes_for_filter = []
    controller_name.classify.constantize.reflect_on_all_associations.map(&:name).each do |x|
      x = x.to_s.singularize.constantize

      next if x.include? "image"

      @attributes_for_filter << x.column_names
    end
  end

  def refresh_token
    @refresh_token = RefreshToken.last
    if @refresh_token.present? && @refresh_token.access_token_expiry.localtime < DateTime.now
      begin
        data = { :redirect_uri => 'Channel_Dispatc-ChannelD-Channe-flynitdm',
          :grant_type => 'refresh_token',
          :refresh_token => @refresh_token.refresh_token
        }
        body = URI.encode_www_form(data)
        @result = HTTParty.post('https://api.ebay.com/identity/v1/oauth2/token'.to_str,
          :body => body,
          :headers => { 'Content-Type' => 'application/x-www-form-urlencoded',
            'Authorization' => 'Basic Q2hhbm5lbEQtQ2hhbm5lbEQtUFJELWRhMjhlYzY5MC00YTlmMzYzYzpQUkQtYTI4ZWM2OTA4ZWE5LTdjNDMtNGZkOS1iZTQzLTBlN2Q=' } )

      rescue
        flash[:alert] = 'Please contact your administration for process'
        redirect_to product_mappings_path
      end
      if @result['error'].present? || @result['errors'].present?
        flash[:alert] = "#{@result['error_description']}"
        redirect_to product_mappings_path
      else @result.body.present?
        @refresh_token.update(access_token: @result['access_token'], access_token_expiry: DateTime.now + @result['expires_in'].to_i.seconds )
      end
    end
    @refresh_token
  end

  def authentication_tokens
    if params['code'].present? && params['expires_in'].present?
      begin
        data = { :redirect_uri => 'Channel_Dispatc-ChannelD-Channe-flynitdm',
          :grant_type => 'authorization_code',
          :code => params['code']
        }
        body=URI.encode_www_form(data)
        @result = HTTParty.post('https://api.ebay.com/identity/v1/oauth2/token'.to_str,
          :body => body,
          :headers => { 'Content-Type' => 'application/x-www-form-urlencoded',
            'Authorization' => 'Basic Q2hhbm5lbEQtQ2hhbm5lbEQtUFJELWRhMjhlYzY5MC00YTlmMzYzYzpQUkQtYTI4ZWM2OTA4ZWE5LTdjNDMtNGZkOS1iZTQzLTBlN2Q=' } )
      rescue
        flash[:alert] = 'Please contact your administration for process'
        redirect_to root_path
      end
      if @result['error'].present? || @result['errors'].present?
        flash[:alert] = "#{@result['error_description']}"
        redirect_to product_mappings_path
      else @result.body.present?
        @refresh_token = RefreshToken.create(access_token: @result['access_token'], access_token_expiry: DateTime.now + @result['expires_in'].to_i.seconds, refresh_token: @result['refresh_token'], refresh_token_expiry: DateTime.now + @result['refresh_token_expires_in'].to_i.seconds )
        flash[:alert] = "Refresh token generated successfully!"
        redirect_to product_mappings_path
      end
    end
  end
end
