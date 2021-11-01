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
    if item['Variations'].present?
      item['Variations']['Variation'].each do |variation|
        multi_product(variation)
      end
    else
      ChannelProduct.create_with(channel_type: 'ebay', item_id: item['ItemID'].to_i,
                                 product_data: item, item_sku: item['SKU'])
                    .find_or_create_by(channel_type: 'ebay', item_id: item['ItemID'].to_i)
    end
  end

  def multi_product(variation)
    ChannelProduct.create_with(channel_type: 'ebay', item_id: item['ItemID'].to_i,
                               product_data: item, item_sku: variation['SKU'])
                  .find_or_create_by(channel_type: 'ebay', item_id: item['ItemID'].to_i, item_sku: variation['SKU'])
  end
end
