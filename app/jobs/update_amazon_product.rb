# frozen_string_literal: true

# amazon product quantity update
class UpdateAmazonProduct < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'amazon').last
    sku = _args.last[:product]
    quantity = _args.last[:quantity]
    remainaing_time = @refresh_token.access_token_expiry.localtime < DateTime.now
    generate_refresh_token if @refresh_token.present? && remainaing_time
    url = 'https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/documents'
    document = {
      "contentType" => "application/json; charset=UTF-8"
    }
    document_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return document_response[:error] unless document_response[:status]

    result = upload_document(@refresh_token.access_token, document_response[:body]['url'], sku, quantity)
    return result[:error] unless result[:status]

    create_feed_response(document_response)
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

  def upload_document(access_token, url, sku, quantity)
    data = {
      "header" => {
        "sellerId" => "A292BGT65ET8F0",
        "version" => "2.0",
        "issueLocale" => "en_US"
      },
      "messages" => [
        {
          "messageId" => 1,
          "sku" => sku,
          "operationType" => "PATCH",
          "productType" => "LUGGAGE",
          "patches" => [
            {
              "op" => "replace",
              "path" => "/attributes/fulfillment_availability",
              "value" => [
                {
                  "fulfillment_channel_code" => "DEFAULT",
                  "quantity" => quantity.to_i
                }
              ]
            }
          ]
        }
      ]
    }
    result = put_document(data, url)
    return_response(result)
  end

  def put_document(data, url)
    body = URI.encode_www_form(data)
    HTTParty.put(
      url.to_str,
      body: body,
      headers: { 'Content-Type' => 'application/json; charset=UTF-8' }
    )
  end

  def return_response(result)
    return { status: true, body: '' } if result.success?

    { status: false, error: result['error_description'] }
  end

  def create_feed_response(response)
    url = 'https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds'
    document = {
      "feedType" => "JSON_LISTINGS_FEED",
      "marketplaceIds" => [
        "A1F83G8C2ARO7P"
      ],
      "inputFeedDocumentId" => response[:body]['feedDocumentId']
    }
    feed_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return feed_response[:error] unless feed_response[:status]

    # get_feed(feed_response[:body]['feedId'])
  end

  def get_feed(feed_id)
    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds/#{feed_id}"
    result = AmazonService.amazon_api(@refresh_token.access_token, url)
    # return puts result unless result[:status]

    # create_order_response(result, url)
  end
end
