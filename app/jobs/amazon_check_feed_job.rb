# frozen_string_literal: true

# amazon feed response status
class AmazonCheckFeedJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'amazon').last
    remainaing_time = @refresh_token.access_token_expiry.localtime > DateTime.now
    generate_refresh_token_amazon if @refresh_token.present? && remainaing_time == false

    feed_id = _args.last[:feed_id] || _args.last['feed_id']
    return 'Feed not found' unless feed_id.present?

    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds/#{feed_id}"
    result = AmazonService.amazon_api(@refresh_token.access_token, url)
    return rescheduled_job(feed_id) unless result[:status] || (result[:body]['processingStatus'].eql? 'DONE')

    check_document(result[:body]['resultFeedDocumentId'])
  end

  def check_document(document_id)
    url = "https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/documents/#{document_id}"
    result = AmazonService.amazon_api(@refresh_token.access_token, url)
    return rescheduled_job(feed_id) unless result[:status] || result[:body]['url'].present?

    response = HTTParty.get(result[:body]['url'])
    return partial_update_channel(response) unless response.dig_deep('MessagesProcessed').eql? response.dig_deep('MessagesSuccessful')

    channel_updated(response.dig_deep('AmazonOrderID'))
  end

  def rescheduled_job(feed_id)
    order_ids = @arguments.first['order_ids'] || @arguments.first[:order_ids]
    job_status_id = @arguments.first['job_status_id'] || @arguments.first[:job_status_id]
    self.class.set(wait: 150.seconds).perform_later(feed_id: feed_id, order_ids: order_ids, error: error, job_status_id: job_status_id)
  end

  def channel_updated(ids)
    ChannelOrder.where(order_id: ids)&.update_all(update_channel: true)
  end

  def partial_update_channel(response)
    order_ids = @arguments.first['order_ids'] || @arguments.first[:order_ids]
    return channel_updated(response.dig_deep('AmazonOrderID')) unless order_ids.present?

    response.dig_deep('ResultDescription').each_with_index do |description, index|
      ChannelOrder.find_by(id: order_ids[index])&.update(update_channel: description)
    end
    channel_updated(response.dig_deep('AmazonOrderID'))
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
end
