# frozen_string_literal: true

# converting response to orders
class CreateChannelOrderResponseJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    require 'uri'
    require 'net/http'
    @refresh_token = RefreshToken.where(channel: 'ebay').last
    channel_response_data = ChannelResponseData.where(channel: 'ebay', api_call: 'getOrders')
    date_format = (Date.today - 2.months).strftime('%FT%T%:z').split('+').first
    date_format = (Date.today).strftime('%FT%T%:z').split('+').first if channel_response_data.present?
    url = "https://api.ebay.com/sell/fulfillment/v1/order?filter=creationdate:%5B#{date_format}.000Z..%5D&limit=200&offset=0"

    @headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
                 'content-type' => 'application/json',
                 'accept' => 'application/json' }

    uri = URI(url)
    request = Net::HTTP.get_response(uri, @headers)
    body = JSON.parse(request.body)
    chanel_data = ChannelResponseData.find_or_initialize_by(channel: 'ebay', api_url: url, api_call: 'getOrders')
    unless chanel_data.status_executed?
      chanel_data.response = body
      if body['errors'].nil?
        chanel_data.status_pending!
        chanel_data.save!
      else
        chanel_data.status_error!
        chanel_data.save!
        return
      end
    end
    date = chanel_data.created_at.to_date
    (1...body['total'].to_i).each_slice(200) do |count|
      offset = count.last
      break unless (offset % 200).zero?

      ebay_url = "https://api.ebay.com/sell/fulfillment/v1/order?filter=creationdate:%5B#{date_format}.000Z..%5D&limit=200&offset=#{offset}"
      chanel_data = ChannelResponseData.find_or_initialize_by(channel: 'ebay', api_url: ebay_url, api_call: 'getOrders')
      chanel_data.status_not_available! if chanel_data.status.blank?
      chanel_data.save!
    end
    fetch_pending_orders(date)
  end

  def fetch_pending_orders(date)
    order_urls = ChannelResponseData.where('api_call = ? and status NOT IN (?) and Date(created_at) = ?', 'getOrders',
                                           %w[pending executed], date)
    order_urls.each do |order_url|
      uri = URI(order_url.api_url)
      count = 0
      loop do
        count += 1
        request = Net::HTTP.get_response(uri, @headers)
        body = JSON.parse(request.body)
        body_response_record = ChannelResponseData.find_by(api_url: order_url.api_url)
        if body['errors'].nil?
          body_response_record.update(channel: 'ebay', response: body, status: 'pending')
          break
        else
          body_response_record.update(channel: 'ebay', response: body)
          body_response_record.status_error!
          break if count == 3
        end
      end
    end
    CreateChannelOrderJob.perform_later
  end
end
