# frozen_string_literal: true

# getting products response from api
class CreateChannelProductJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @response_items = ChannelResponseData.all
    @response_items.each do |response_item|
      next unless (response_item.api_call == 'GetMyeBaySelling') && response_item.status_pending?

      next unless response_item.response['GetMyeBaySellingResponse']['ActiveList'].present?

      response_item.response['GetMyeBaySellingResponse']['ActiveList']['ItemArray']['Item'].each do |item|
        create_or_update_product(item)
      end
      response_item.update(status: 'executed')
    end
  end

  def create_or_update_product(item)
    picture = item['PictureDetails'].present? ? item['PictureDetails']['GalleryURL'] : nil

    if item['Variations'].present? && (item['Variations']['Variation'].class.eql? Array) && item['Variations']['Variation'].count > 1
      multi_product(item, item['Variations']['Variation'], picture)
    elsif item['Variations'].present? && (item['Variations']['Variation'].class.eql? Hash)
      single_variation_multi_product(item, item['Variations']['Variation'], picture)
    else
      product = ChannelProduct
                .create_with(channel_type: 'ebay', listing_id: item['ItemID'].to_i,
                             product_data: item, item_sku: item['SKU'], item_image: picture, item_name: item['Title'], item_price: item['BuyItNowPrice'])
                .find_or_create_by(channel_type: 'ebay', listing_id: item['ItemID'].to_i, item_sku: item['SKU'])
      ChannelOrderItem.where(sku: product.item_sku)&.update_all(channel_product_id: product.id)
    end
  end

  def multi_product(item, variations, picture)
    variations.each do |variation|
      product = ChannelProduct
                .create_with(channel_type: 'ebay', listing_id: item['ItemID'].to_i, product_data: item,
                             item_sku: variation['SKU'], item_image: picture, item_name: variation['VariationTitle'], item_price: item['BuyItNowPrice'])
                .find_or_create_by(channel_type: 'ebay', listing_id: item['ItemID'].to_i, item_sku: variation['SKU'])
      ChannelOrderItem.where(sku: product.item_sku)&.update_all(channel_product_id: product.id)
    end
  end

  def single_variation_multi_product(item, variation, picture)
    product = ChannelProduct
                .create_with(channel_type: 'ebay', listing_id: item['ItemID'].to_i, product_data: item,
                             item_sku: variation['SKU'], item_image: picture, item_name: variation['VariationTitle'], item_price: item['BuyItNowPrice'])
                .find_or_create_by(channel_type: 'ebay', listing_id: item['ItemID'].to_i, item_sku: variation['SKU'])
      ChannelOrderItem.where(sku: product.item_sku)&.update_all(channel_product_id: product.id)
  end
end
