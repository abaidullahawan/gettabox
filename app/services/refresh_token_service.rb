# frozen_string_literal: true

# Api calls for refresh token
class RefreshTokenService
  def self.refresh_token_api(refresh_token, credential)
    data = { redirect_uri: credential.redirect_uri,
             grant_type: credential.grant_type,
             refresh_token: refresh_token.refresh_token }
    result = api_post_request(data, credential)
    return_response(result)
  end

  def self.authentication_token_api(code, credential)
    data = { redirect_uri: credential.redirect_uri,
             grant_type: 'authorization_code',
             code: code }
    result = api_post_request(data, credential)
    return_response(result)
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

  def self.return_response(result)
    return { status: true, body: JSON.parse(result.body) } if result.success?

    { status: false, error: result['error_description'] }
  end

  def self.amazon_refresh_token(refresh_token)
    data = { client_id: 'amzn1.application-oa2-client.f849ef8d13a94a758e11ac787095ce1e',
             refresh_token: refresh_token.refresh_token,
             client_secret: '9b9759b5b27e0d8233d33b4a45e07d0b876a4d279dafd3e2382d76996da00102',
             grant_type: 'refresh_token' }
    result = amazon_request_api(data)
    return_response(result)
  end

  def self.amazon_request_api(data)
    body = URI.encode_www_form(data)
    HTTParty.post(
      'https://api.amazon.com/auth/o2/token'.to_str,
      body: body,
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    )
  end
end
