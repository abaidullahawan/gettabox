# frozen_string_literal: true

# Api calls for refresh token
class RefreshTokenService
  def self.refresh_token_api(refresh_token, credential)
    data = { redirect_uri: credential.redirect_uri,
             grant_type: credential.grant_type,
             refresh_token: refresh_token.refresh_token }
    api_post_request(data, credential)
  end

  def self.authentication_token_api(code, credential)
    data = { redirect_uri: credential.redirect_uri,
             grant_type: 'authorization_code',
             code: code }
    api_post_request(data, credential)
  end

  def self.api_post_request(data, credential)
    body = URI.encode_www_form(data)
    HTTParty.post(
      'https://api.ebay.com/identity/v1/oauth2/token'.to_str,
      body: body,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                 'Authorization' => credential.authorization }
    )
  end
end
