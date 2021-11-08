# frozen_string_literal: true

# Device code verification call
class AmazonDeviceCodeService
  def self.device_code_api
    data = { response_type: 'device_code',
             client_id: 'amzn1.application-oa2-client.43590423fc3942f387d9da76e6219178',
             scope: 'postal_code' }
    result = code_api_request(data)
    return_response(result)
  end

  def self.code_api_request(data)
    body = URI.encode_www_form(data)
    HTTParty.post(
      'https://api.amazon.com/auth/o2/create/codepair'.to_str,
      body: body,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                 'charset' => 'UTF-8'}
    )
  end

  def self.refresh_token_api(user_code, device_code)
    data = { user_code: user_code,
             device_code: device_code,
             grant_type: 'device_code' }
    result = token_api_request(data)
    return_response(result)
  end

  def self.token_api_request(data)
    body = URI.encode_www_form(data)
    HTTParty.post(
      'https://api.amazon.com/auth/o2/token'.to_str,
      body: body,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                 'charset' => 'UTF-8',})
  end

  def self.return_response(result)
    return { status: true, body: JSON.parse(result.body) } if result.success?

    { status: false, error: result['error_description'] }
  end
end
