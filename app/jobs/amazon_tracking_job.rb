# frozen_string_literal: true

# tracking update on amazon
class AmazonTrackingJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'amazon').last
    remainaing_time = @refresh_token.access_token_expiry.localtime > DateTime.now
    generate_refresh_token_amazon if @refresh_token.present? && remainaing_time == false

    order_ids = _args.last[:order_ids] || _args.last['order_ids']
    order_ids = ChannelOrder.where(id: order_ids, channel_type: 'amazon').pluck(:id)
    return 'Orders not found' unless order_ids.present?

    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/documents"
    document ={
      contentType: "text/xml; charset=UTF-8"
    }
    order_ids.each_slice(7).with_index(1) do |chunk, index|
      sleep(10.seconds) if index > 1
      document_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
      return perform_later_queue(chunk, document_response[:error]) unless document_response[:status]

      result = upload_document(@refresh_token.access_token, document_response[:body]['url'], chunk)
      return perform_later_queue(chunk, result[:error]) unless result[:status]

      create_feed_response(document_response, chunk)
    end
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

  def upload_document(access_token, url, ids)
    orders = ChannelOrder.where(id: ids, channel_type: 'amazon')

    xml_data = Builder::XmlMarkup.new
    xml_data.instruct!
    xml_data.AmazonEnvelope('xsi:noNamespaceSchemaLocation' => 'amzn-envelope.xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') do
      xml_data.Header do
        xml_data.DocumentVersion '1.01'
        xml_data.MerchantIdentifier 'A292BGT65ET8F0'
      end
      xml_data.MessageType 'OrderFulfillment'
      orders.each.with_index(1) do |order, index|
        xml_data.Message do
          carrier = order.trackings&.first&.carrier
          service = order.trackings&.first&.service
          tracking_no = order.trackings&.first&.tracking_no
          order_id = order.order_id
          time = Time.zone.now.dst? ? (Time.zone.now - 1.hour).strftime('%Y-%m-%dT%H:%M:%S.%LZ') : Time.zone.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
          xml_data.MessageID index
          xml_data.OrderFulfillment do
            xml_data.AmazonOrderID order_id
            xml_data.FulfillmentDate time
            xml_data.FulfillmentData do
              xml_data.CarrierCode carrier
              xml_data.ShippingMethod service
              xml_data.ShipperTrackingNumber tracking_no
            end
          end
        end
      end
    end

    result = put_document(xml_data, url)
    return_response(result)
  end

  def put_document(data, url)
    @body = data.to_xml.split('<to_xml/>').first
    HTTParty.put(
      url.to_str,
      body: @body,
      headers: { 'Content-Type' => 'text/xml; charset=UTF-8' }
    )
  end

  def return_response(result)
    return { status: true, body: result } if result.success?

    { status: false, error: result['error_description'] }
  end

  def create_feed_response(result, ids)
    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds"
    document = {
      feedType: "POST_ORDER_FULFILLMENT_DATA",
      marketplaceIds: [
        "A1F83G8C2ARO7P"
      ],
      inputFeedDocumentId: result[:body]['feedDocumentId']
    }
    feed_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return perform_later_queue([ids], feed_response[:error]) unless feed_response[:status]

    AmazonCheckFeedJob.perform_later(feed_id: feed_response[:body]['feedId'], records: ids, job_status_id: @arguments.first[:job_status_id])
  end

  def perform_later_queue(ids, error)
    credential = Credential.find_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = Time.zone.now.no_dst > wait_time ? Time.zone.now.no_dst : wait_time + 10.seconds
    credential.update(redirect_uri: 'AmazonTrackingJob', authorization: ids, created_at: wait_time)
    elapsed_seconds = wait_time - Time.zone.now.no_dst
    # job_data = self.class.set(wait: elapsed_seconds.seconds).perform_later(order_ids: ids, error: error)
    JobStatus.create(name: self.class.to_s, status: 'retry', arguments: { order_ids: ids, error: error }, perform_in: elapsed_seconds.seconds)
  end
end
