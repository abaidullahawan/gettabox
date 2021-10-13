class CreateChannelOrderResponseJob < ApplicationJob
  queue_as :default

  def perform(*args)
    require 'uri'
    require 'net/http'
    @order_urls = ChannelResponseData.all
    @refresh_token = RefreshToken.last
    @order_urls.each do |order_url|
      if (((order_url.status == "not available") || (order_url.status == "error")) && (order_url.api_call == "getOrders"))
        @url = order_url.api_url
        @headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
        'content-type' => "application/json",
        'accept' => "application/json"
        }
        @uri = URI(@url)
        request = Net::HTTP.get_response(@uri, @headers)
        @body = JSON.parse(request.body)
        @body_response_record = ChannelResponseData.find_by(api_url: @url)
        if @body['errors'].nil?
          @body_response_record.update(channel: "ebay", response: @body, status: "panding")
        else
          @body_response_record.update(channel: "ebay", response: @body, status: "error")
          break
        end
      end
    end
  end
end
