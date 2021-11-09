# frozen_string_literal: true

# restricting headers to be capitalize
module Net::HTTPHeader
  def capitalize(name)
    name
  end
  private :capitalize
end

# Api calls for amazon orders
class OrdersAmzService
  def self.orders_amz
    access_token = RefreshToken.where(channel: 'amazon').last.access_token
    access_key = 'AKIA6RGM5COAWQNAAHWJ'
    secret_key = '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'
    url = 'https://sellingpartnerapi-eu.amazon.com/orders/v0/orders?MarketplaceIds=A1F83G8C2ARO7P&CreatedAfter=2021-11-08T17%3A00%3A00'

    signature = signature_generator(access_key, secret_key, access_token, url)
    response = api_call(signature, access_token, url)
    result = return_response(response)
    return result unless result[:status]

    create_order_response(result, url)
    # next_token = result[:body]['payload']['NextToken']
    # next_orders_amz(next_token, access_token, access_key, secret_key, url) if next_token.present?
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

  def self.signature_generator(access_key, secret_key, access_token, url)
    signer = Aws::Sigv4::Signer.new(access_key_id: access_key, region: 'eu-west-1', secret_access_key: secret_key,
                                    service: 'execute-api')

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

    { status: false, error: response['errors'][0]['details'] }
  end

  def self.next_orders_amz(next_token, access_token, access_key, secret_key, url)
    signature = next_signature_generator(access_key, secret_key, access_token, url, next_token)
    response = next_api_call(signature, access_token, url, next_token)
    result = return_response(response)
    return result unless result[:status]

    create_order_response(result, url)
    new_next_token = result[:body]['payload']['NextToken']
    next_orders_amz(new_next_token, access_token, access_key, secret_key, url) if new_next_token.present?
  end

  def self.next_signature_generator(access_key, secret_key, access_token, url, next_token)
    signer = Aws::Sigv4::Signer.new(access_key_id: access_key, region: 'eu-west-1',
                                    secret_access_key: secret_key, service: 'execute-api')

    signer.sign_request(
      http_method: 'GET', url: url,
      headers: {
        'host' => 'sellingpartnerapi-eu.amazon.com',
        'user-agent' => 'ChannelDispatch (Language=Ruby)',
        'x-amz-access-token' => access_token,
        'next-token' => next_token
      }
    )
  end

  def self.next_api_call(signature, access_token, url, next_token)
    HTTParty.send(
      :get, url,
      headers: {
        'host' => signature.headers['host'], 'user-agent' => 'ChannelDispatch (Language=Ruby)',
        'x-amz-access-token' => access_token,
        'x-amz-content-sha256' => signature.headers['x-amz-content-sha256'],
        'x-amz-date' => signature.headers['x-amz-date'],
        'authorization' => signature.headers['authorization'],
        'next-token' => next_token
      }
    )
  end

  def self.create_order_response(result, url)
    ChannelResponseData.create(
      channel: 'amazon', response: result[:body],
      api_call: 'getOrders', api_url: url, status: 'pending'
    )
  end

  # def self.create_orders(result)
  #   result[:body]['payload']['Orders'].each do |order|
  #     channel_order_record = ChannelOrder.find_or_initialize_by(ebayorder_id: order['AmazonOrderId'],
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
end
