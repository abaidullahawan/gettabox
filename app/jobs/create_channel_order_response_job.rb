class CreateChannelOrderResponseJob < ApplicationJob
  queue_as :default

  def perform(*args)
    require 'uri'
    require 'net/http'
    @order_urls = ChannelResponseData.all
    @refresh_token = RefreshToken.last
    @order_urls.each do |order_url|
      if order_url.api_call == "getOrders"
        @url = order_url.api_url
        @headers = { 'authorization' => "Bearer <#{@refresh_token.access_token}>",
        'content-type' => "application/json",
        'accept' => "application/json"
        }
        @uri = URI(@url)
        loop do
          request = Net::HTTP.get_response(@uri, @headers)
          @body = JSON.parse(request.body)
          if @body['errors'].nil?
            body_response = ChannelResponseData.find_by(api_url: @url)
            body_response.update(channel: "ebay", response: @body)
            break
          end
        end
      end
    end
  end
end
