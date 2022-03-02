# frozen_string_literal: true

# tracking update on amazon
class AmazonTrackingJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'amazon').last
    remainaing_time = @refresh_token.access_token_expiry.localtime > DateTime.now
    generate_refresh_token_amazon if @refresh_token.present? && remainaing_time == false

    order_ids = _args.last[:order_ids]
    return 'Orders not found' unless order_ids.present?

    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/documents"
    document ={
      contentType: "text/xml; charset=UTF-8"
    }
    document_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return document_response[:error] unless document_response[:status]

    result = upload_document(@refresh_token.access_token, document_response[:body]['url'], order_ids)
    return result[:error] unless result[:status]

    create_feed_response(document_response, order_ids)
  end

  def generate_refresh_token_amazon
    result = RefreshTokenService.amazon_refresh_token(@refresh_token)
    return update_refresh_token(result[:body], @refresh_token) if result[:status]
  end

  def update_refresh_token(result, refresh_token)
    refresh_token.update(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds
    )
  end

  def upload_document(access_token, url, order_ids)
    orders = ChannelOrder.where(id: order_ids, channel_type: 'amazon')

    xml_data = Builder::XmlMarkup.new
    xml_data.instruct!
    xml_data.AmazonEnvelope('xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') do
      xml_data.Header do
        xml_data.DocumentVersion '1.01'
        xml_data.MerchantIdentifier 'A292BGT65ET8F0'
      end
      xml_data.MessageType 'OrderFulfillment'
      xml_data.Message do
        orders.each.with_index(1) do |order, index|
          xml_data.MessageID index
          xml_data.OrderFulfillment do
            xml_data.AmazonOrderID order.order_id
            xml_data.FulfillmentDate Time.zone.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_data.FulfillmentData do
              xml_data.CarrierCode order.trackings&.first&.carrier
              xml_data.ShippingMethod order.trackings&.first&.service
              xml_data.ShipperTrackingNumber order.trackings&.first&.tracking_no
            end
          end
        end
      end
    end

    result = put_document(xml_data, url)
    return_response(result)
  end

  def put_document(data, url)
    body = data.to_xml.split('<inspect/>').first
    HTTParty.put(
      url.to_str,
      body: body,
      headers: { 'Content-Type' => 'text/xml; charset=UTF-8' }
    )
  end

  def return_response(result)
    return { status: true, body: result } if result.success?

    { status: false, error: result['error_description'] }
  end

  def create_feed_response(result, order_ids)
    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds"
    document = {
      feedType: "POST_ORDER_FULFILLMENT_DATA",
      marketplaceIds: [
        "A1F83G8C2ARO7P"
      ],
      inputFeedDocumentId: result[:body]['feedDocumentId']
    }
    feed_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return feed_response[:error] unless feed_response[:status]

    byebug
    channel_updated(order_ids)
    # get_feed(feed_response[:body]['feedId'])
  end

  def get_feed(feed_id)
    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds/#{feed_id}"
    result = AmazonService.amazon_api(@refresh_token.access_token, url)
    # return puts result unless result[:status]

    # create_order_response(result, url)
  end

  def channel_updated(order_ids)
    ChannelOrder.where(order_id: order_ids).update_all(update_channel: true)
  end
end
