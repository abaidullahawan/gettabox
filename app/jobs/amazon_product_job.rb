# frozen_string_literal: true

# orders for amazon
class AmazonProductJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token_amazon = RefreshToken.where(channel: 'amazon').last
    remainaing_time = @refresh_token_amazon.access_token_expiry.localtime > DateTime.now
    generate_refresh_token_amazon if @refresh_token_amazon.present? && remainaing_time == false
    url = 'https://sellingpartnerapi-eu.amazon.com/reports/2021-06-30/documents/amzn1.spdoc.1.3.bb1456cc-7382-40db-9a6a-6a27d4b9fe61.T1ZC9CBIMPWKA.300'
    result = AmazonService.amazon_api(@refresh_token_amazon.access_token, url)
    return puts result unless result[:status]

    create_channel_products(result)
  end

  def generate_refresh_token_amazon
    result = RefreshTokenService.amazon_refresh_token(@refresh_token_amazon)
    return update_refresh_token(result[:body], @refresh_token_amazon) if result[:status]
  end

  def update_refresh_token(result, refresh_token)
    refresh_token.update(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds
    )
  end

  def create_channel_products(result)
    url = result[:body]['url']
    text = Net::HTTP.get(URI.parse(url))
    return if text.include?('Request has expired')

    # text.sub! '\xA0', ' '
    csv = CSV.parse(text, headers: true, col_sep: "\t", quote_char: nil)
    csv.each do |row|
      hash = row.to_hash
      hash['item-name'] = hash['item-name']&.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      hash['seller-sku'] = hash['seller-sku']&.encode('UTF-8', invalid: :replace, undef: :replace, replace: ' ')
      hash['item-description'] = hash['item-description']&.encode('UTF-8', invalid: :replace, undef: :replace, replace: ' ')
      channel_product = ChannelProduct.find_or_initialize_by(
        channel_type: 'amazon', item_id: hash['listing-id'],
        item_sku: hash['seller-sku']
      )
      channel_product.update(product_data: hash,
        created_at: hash['open-date'].to_time, status: 0)
    end
  end

  def to_utf8(hash)
    Hash[
      hash.collect do |k, v|
        if (v.respond_to?(:to_utf8))
          [ k, v.to_utf8 ]
        elsif (v.respond_to?(:encoding))
          [ k, v.dup.encode('UTF-8') ]
        else
          [ k, v ]
        end
      end
    ]
  end
end