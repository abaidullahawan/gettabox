# frozen_string_literal: true

# orders for amazon
class AmazonProductJob < ApplicationJob
  include ERB::Util
  queue_as :default

  def perform(*_args)
    @refresh_token_amazon = RefreshToken.where(channel: 'amazon').last
    remainaing_time = @refresh_token_amazon.access_token_expiry.localtime < DateTime.now
    generate_refresh_token_amazon if @refresh_token_amazon.present? && remainaing_time
    url = 'https://sellingpartnerapi-eu.amazon.com/reports/2021-06-30/reports'
    document = {
      reportType: 'GET_MERCHANT_LISTINGS_DATA', marketplaceIds: ['A1F83G8C2ARO7P']
    }
    result = AmazonCreateReportService.create_report(@refresh_token_amazon.access_token, url, document)
    return result[:error] unless result[:status]

    get_report(@refresh_token_amazon.access_token, url)
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

    create_products(text)
  end

  def create_products(text)
    csv = CSV.parse(text, headers: true, col_sep: "\t", quote_char: nil)
    csv.each do |row|
      hash = filter_hash(row)
      channel_product = ChannelProduct.find_or_initialize_by(
        channel_type: 'amazon', item_id: hash['listing-id'],
        item_sku: hash['seller-sku']
      )
      channel_product.update(product_data: hash, created_at: hash['open-date'].to_time,
                             item_name: hash['item-name'], item_quantity: hash['quantity'].to_i)
    end
  end

  def filter_hash(row)
    hash = row.to_hash
    hash['item-name'] = hash['item-name']&.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    hash['seller-sku'] = hash['seller-sku']&.encode('UTF-8', invalid: :replace, undef: :replace, replace: ' ')
    hash['item-description'] = hash['item-description']&.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    hash
  end

  def channel_product_images(channel_products, access_token)
    channel_products.each do |product|
      asin = u(product.product_data['asin1'] || product.product_data['asin2'] || product.product_data['asin3'])
      url = "https://sellingpartnerapi-eu.amazon.com/catalog/2020-12-01/items/#{asin}?includedData=images&marketplaceIds=A1F83G8C2ARO7P"
      result = AmazonService.amazon_api(access_token, url)
      update_channel_product(product, result)
    end
  end

  def update_channel_product(product, result)
    return product.update(error_message: result[:error]) unless result[:status]

    product.update(item_image: result[:body]['images'].first['images'].last['link'])
  end

  def get_report(access_token, url)
    url += '?reportTypes=GET_MERCHANT_LISTINGS_DATA&processingStatuses=DONE'
    result = AmazonService.amazon_api(access_token, url)
    return result[:error] unless result[:status]

    document_id = result[:body]['reports'][0]['reportDocumentId']
    url = "https://sellingpartnerapi-eu.amazon.com/reports/2021-06-30/documents/#{document_id}"
    result = AmazonService.amazon_api(access_token, url)
    return result[:error] unless result[:status]

    create_channel_products(result)
    channel_products = ChannelProduct.where(channel_type: 'amazon', item_image: nil)
    channel_product_images(channel_products, @refresh_token_amazon.access_token) if channel_products.present?
  end
end
