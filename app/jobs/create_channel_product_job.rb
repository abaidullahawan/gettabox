class CreateChannelProductJob < ApplicationJob
  queue_as :default

  def perform(*args)
    @response_items = ChannelResponseData.all
    @response_items.each do |response_item|
      if ((response_item.api_call == "GetMyeBaySelling") && (response_item.status == "panding"))
        response_item.response['GetMyeBaySellingResponse']['ActiveList']['ItemArray']['Item'].each do |item|
          if item['Variations'].present?
            item['Variations']['Variation'].each do |variation|
              ChannelProduct.create_with(channel_type: 'ebay', item_id: item["ItemID"].to_i, product_data: item, item_sku: variation["SKU"]).find_or_create_by(channel_type: 'ebay', item_id: item["ItemID"].to_i, item_sku: variation["SKU"])
            end
          else
            ChannelProduct.create_with(channel_type: 'ebay', item_id: item["ItemID"].to_i, product_data: item, item_sku: item["SKU"]).find_or_create_by(channel_type: 'ebay', item_id: item["ItemID"].to_i)
          end
        end
        response_item.update(status: "executed")
      end
    end
  end
end
