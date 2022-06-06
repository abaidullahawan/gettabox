# frozen_string_literal: true

# restricting headers to be capitalize
module Net::HTTPHeader
  def capitalize(name)
    name
  end
  private :capitalize
end

# Api calls for amazon orders
class AmazonService
  def self.amazon_api(access_token, url)
    signature = signature_generator(access_token, url)
    response = api_call(signature, access_token, url)
    sleep 5
    # byebug unless response.success?
    return_response(response)
  end

  def self.api_call(signature, access_token, url)
    HTTParty.send(
      :get, url,
      headers: {
        'host' => signature.headers['host'], 'user-agent' => 'ChannelDispatch (Language=Ruby)',
        'x-amz-access-token' => access_token,
        'x-amz-content-sha256' => signature.headers['x-amz-content-sha256'],
        'x-amz-date' => signature.headers['x-amz-date'],
        'authorization' => signature.headers['authorization']
      }
    )
  end

  def self.signature_generator(access_token, url)
    signer = Aws::Sigv4::Signer.new(access_key_id: Settings.amazon_access_key, region: 'eu-west-1',
                                    secret_access_key: Settings.amazon_secret_key, service: 'execute-api')

    signer.sign_request(
      http_method: 'GET', url: url,
      headers: {
        'host' => 'sellingpartnerapi-eu.amazon.com',
        'user-agent' => 'ChannelDispatch (Language=Ruby)',
        'x-amz-access-token' => access_token
      }
    )
  end

  def self.return_response(response)
    return { status: true, body: JSON.parse(response.body) } if response.success?

    { status: false, error: response['errors'][0]['message'] }
  end

  def self.next_orders_amz(next_token, access_token, url)
    data = {
      'NextToken' => next_token
    }
    url = url + '&' + URI.encode_www_form(data)
    signature = next_signature_generator(access_token, url)
    response = next_api_call(signature, access_token, url)
    sleep 5
    return_response(response)
  end

  def self.next_signature_generator(access_token, url)
    signer = Aws::Sigv4::Signer.new(access_key_id: Settings.amazon_access_key, region: 'eu-west-1',
                                    secret_access_key: Settings.amazon_secret_key, service: 'execute-api')
    signer.sign_request(
      http_method: 'GET', url: url,
      headers: {
        'host' => 'sellingpartnerapi-eu.amazon.com',
        'user-agent' => 'ChannelDispatch (Language=Ruby)',
        'x-amz-access-token' => access_token,
        # 'content-type' => 'application/x-www-form-urlencoded',
        'accept' => 'application/json'
      }
    )
  end

  def self.next_api_call(signature, access_token, url)
    HTTParty.send(
      :get, url,
      headers: {
        'host' => signature.headers['host'], 'user-agent' => 'ChannelDispatch (Language=Ruby)',
        'x-amz-access-token' => access_token,
        'x-amz-content-sha256' => signature.headers['x-amz-content-sha256'],
        'x-amz-date' => signature.headers['x-amz-date'],
        'authorization' => signature.headers['authorization'],
        # 'content-type' => 'application/x-www-form-urlencoded',
        'accept' => 'application/json'
      }
    )
  end

  # def self.create_orders(result)
  #   result[:body]['payload']['Orders'].each do |order|
  #     channel_order_record = ChannelOrder.find_or_initialize_by(order_id: order['AmazonOrderId'],
  #                                                               channel_type: 'amazon')

  #     channel_order_record.order_data = order
  #     channel_order_record.created_at = order['PurchaseDate']
  #     channel_order_record.order_status = order['OrderStatus']
  #     channel_order_record.total_amount = order['OrderTotal']['Amount']
  #     address = "#{order['ShippingAddress']['PostalCode']} #{order['ShippingAddress']['City']} #{order['ShippingAddress']['CountryCode']}" if order['ShippingAddress'].present?
  #     channel_order_record.address = address
  #     channel_order_record.save
  #   end
  # end

  def self.amazon_product_api(url, access_token)
    signature = signature_generator(access_token, url)
    response = api_call(signature, access_token, url)
    sleep 5
    result = return_response(response)
    return return_response(response) if result[:status]

    limited_tries(result, url, access_token)
  end

  def self.limited_tries(result, url, access_token)
    @limit = 0 if @limit.blank? || @limit >= 3
    @limit += 1
    sleep 5
    return amazon_product_api(url, access_token) if @limit < 3

    result
  end
end
