# frozen_string_literal: true

# amazon product quantity update
class UpdateAmazonProduct < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'amazon').last
    # sku = _args.last[:product] || _args.last['product']
    # quantity = _args.last[:quantity] || _args.last['quantity']
    products = _args&.last.try(:[], 'products')
    products = ChannelProduct.where('updated_at > ?', DateTime.now - 30.minutes).where(channel_type: 'amazon').pluck(:item_sku, :item_quantity) if products.nil? || products.empty?
    return 'Products not found' if products.nil? || products.empty?

    remainaing_time = @refresh_token.access_token_expiry.localtime < DateTime.now
    generate_refresh_token if @refresh_token.present? && remainaing_time
    url = 'https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/documents'
    document = {
      "contentType" => "application/json; charset=UTF-8"
    }
    products.each_slice(20).with_index do |chunk, index|
      next if index.zero?

      perform_later_queue(chunk, 'Updating in chunks')
    end
    document_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return perform_later_queue(products.first(20), document_response[:error]) unless document_response[:status]

    result = upload_document(@refresh_token.access_token, document_response[:body]['url'], products.first(20))
    return perform_later_queue(products.first(20), result[:error]) unless result[:status]

    create_feed_response(document_response, products.first(20))
  end

  def generate_refresh_token
    result = RefreshTokenService.amazon_refresh_token(@refresh_token)
    update_refresh_token(result[:body], @refresh_token) if result[:status]
  end

  def update_refresh_token(result, refresh_token)
    refresh_token.update(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds
    )
  end

  def upload_document(access_token, url, products)
    data = {
      "header" => {
        "sellerId" => "A292BGT65ET8F0",
        "version" => "2.0",
        "issueLocale" => "en_US"
      },
      "messages" =>
        products.each.with_index(1).map do |product, index|
          {
            "messageId" => index,
            "sku" => product.first,
            "operationType" => "PATCH",
            "productType" => "LUGGAGE",
            "patches" => [
              {
                "op" => "replace",
                "path" => "/attributes/fulfillment_availability",
                "value" => [
                  {
                    "fulfillment_channel_code" => "DEFAULT",
                    "quantity" => product.last.to_i
                  }
                ]
              }
            ]
          }
        end
    }
    result = put_document(data, url)
    return_response(result)
  end

  def put_document(data, url)
    # body = URI.encode_www_form(data)
    HTTParty.put(
      url.to_str,
      body: data.to_json,
      headers: { 'Content-Type' => 'application/json; charset=UTF-8' }
    )
  end

  def return_response(result)
    return { status: true, body: '' } if result.success?

    { status: false, error: result['error_description'] }
  end

  def create_feed_response(response, products)
    url = 'https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds'
    document = {
      "feedType" => "JSON_LISTINGS_FEED",
      "marketplaceIds" => [
        "A1F83G8C2ARO7P"
      ],
      "inputFeedDocumentId" => response[:body]['feedDocumentId']
    }
    feed_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return perform_later_queue(products, feed_response[:error]) unless feed_response[:status]

    # get_feed(feed_response[:body]['feedId'])
  end

  def get_feed(feed_id)
    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds/#{feed_id}"
    result = AmazonService.amazon_api(@refresh_token.access_token, url)
    # return puts result unless result[:status]

    # create_order_response(result, url)
  end

  def perform_later_queue(products, error)
    credential = Credential.find_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = DateTime.now > wait_time ? DateTime.now + 120.seconds : wait_time + 120.seconds
    credential.update(redirect_uri: 'AmazonTrackingJob', authorization: products, created_at: wait_time)
    elapsed_seconds = wait_time - DateTime.now
    # job_data = self.class.set(wait: elapsed_seconds.seconds).perform_later(products: products, error: error)
    JobStatus.create(name: self.class.to_s, status: 'retry', arguments: { products: products, error: error }, perform_in: elapsed_seconds.seconds)
  end
end
