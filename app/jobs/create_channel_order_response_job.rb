# frozen_string_literal: true

# converting response to orders
class CreateChannelOrderResponseJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    require 'uri'
    require 'net/http'
    @refresh_token = RefreshToken.last

    url = 'https://api.ebay.com/sell/fulfillment/v1/order?&limit=200&offset=0'

    @headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
                 'content-type' => 'application/json',
                 'accept' => 'application/json' }

    uri = URI(url)
    request = Net::HTTP.get_response(uri, @headers)
    body = JSON.parse(request.body)
    chanel_data = ChannelResponseData.find_or_initialize_by(channel: 'ebay', api_url: url, api_call: 'getOrders')
    if chanel_data.status_executed?
      chanel_data.save!
    else
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
    (1...body['total'].to_i).each_slice(200) do |count|
      offset = count.last
      break unless (offset % 200).zero?

      ebay_url = "https://api.ebay.com/sell/fulfillment/v1/order?&limit=200&offset=#{offset}"
      chanel_data = ChannelResponseData.find_or_initialize_by(channel: 'ebay', api_url: ebay_url, api_call: 'getOrders')
      chanel_data.status_not_available! if chanel_data.status.blank?
      chanel_data.save!
    end
    fetch_panding_orders
  end

  def fetch_panding_orders
    order_urls = ChannelResponseData.where(api_call: 'getOrders').where.not(status: 'pending')
    order_urls.each do |order_url|
      next unless order_url.status_executed? && order_url.response['orders'].count == 200

      uri = URI(order_url.api_url)
      count = 0
      loop do
        count += 1
        request = Net::HTTP.get_response(uri, @headers)
        body = JSON.parse(request.body)
        body_response_record = ChannelResponseData.find_by(api_url: order_url.api_url)
        if body['errors'].nil?
          body_response_record.update(channel: 'ebay', response: body, status: 'panding')
          break
        else
          body_response_record.update(channel: 'ebay', response: body, status: 'error')
          break if count == 3
        end
      end
    end
    CreateChannelOrderJob.perform_later
  end
end
