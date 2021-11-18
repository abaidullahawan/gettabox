# frozen_string_literal: true

# getting products response from api
class CreateChannelProductJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @response_items = ChannelResponseData.all
    @response_items.each do |response_item|
      next unless (response_item.api_call == 'GetMyeBaySelling') && response_item.status_pending?

      response_item.response['GetMyeBaySellingResponse']['ActiveList']['ItemArray']['Item'].each do |item|
        create_or_update_product(item)
      end
      response_item.update(status: 'executed')
    end
  end

  def create_or_update_product(item)
    return multi_product(item, item['Variations']['Variation']) if item['Variations'].present?

    ChannelProduct.create_with(channel_type: 'ebay', item_id: item['ItemID'].to_i,
                               product_data: item, item_sku: item['SKU'], item_quantity: item['Quantity'],
                               item_image: item['PictureDetails']['GalleryURL'], item_name: item['Title'])
                  .find_or_create_by(channel_type: 'ebay', item_id: item['ItemID'].to_i)
  end

  def multi_product(item, variations)
    variations.each do |variation|
      ChannelProduct.create_with(channel_type: 'ebay', item_id: item['ItemID'].to_i,
                                 product_data: item, item_sku: variation['SKU'],
                                 item_quantity: variation['Quantity'],
                                 item_image: item['PictureDetails']['GalleryURL'],
                                 item_name: variation['VariationTitle'])
                    .find_or_create_by(channel_type: 'ebay', item_id: item['ItemID'].to_i, item_sku: variation['SKU'])
    end
  end
end
