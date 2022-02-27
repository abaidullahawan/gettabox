# frozen_string_literal: true

# restricting headers to be capitalize
module Net::HTTPHeader
  def capitalize(name)
    name
  end
  private :capitalize
end

# Api calls for amazon orders
class AmazonCreateReportService
  def self.create_report(access_token, url, document)
    signature = post_signature_generator(access_token, url, document)
    response = post_api_call(access_token, signature, url, document)
    sleep 5
    return_response(response)
  end

  def self.post_signature_generator(access_token, url, document)
    signer = Aws::Sigv4::Signer.new(access_key_id: Settings.amazon_access_key, region: 'eu-west-1',
                                    secret_access_key: Settings.amazon_secret_key, service: 'execute-api')

    signer.sign_request(
      http_method: 'POST', url: url,
      headers: {
        'host' => 'sellingpartnerapi-eu.amazon.com', 'user-agent' => 'test (Language=Ruby)',
        'x-amz-access-token' => access_token, 'content-type' => 'application/json'
      },
      body: document.to_json
    )
  end

  def self.post_api_call(access_token, signature, url, document)
    HTTParty.post(url,
                  headers: {
                    'host' => signature.headers['host'], 'content-type' => 'application/json',
                    'user-agent' => 'test (Language=Ruby)',
                    'x-amz-access-token' => access_token,
                    'x-amz-content-sha256' => signature.headers['x-amz-content-sha256'],
                    'x-amz-date' => signature.headers['x-amz-date'],
                    'authorization' => signature.headers['authorization']
                  },
                  body: document.to_json)
  end

  def self.return_response(response)
    return { status: true, body: JSON.parse(response.body) } if response.success?

    { status: false, error: response['errors'][0]['message'] }
  end
end
