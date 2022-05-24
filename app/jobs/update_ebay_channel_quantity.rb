# frozen_string_literal: true

# converting response to products
class UpdateEbayChannelQuantity < ApplicationJob
  queue_as :default

  def perform(*_args)

    products = ChannelProduct.where(item_quantity_changed: true, channel_type: 'ebay')
    return 'Products not found' if products.nil? || products.empty?

    products.each do |product|
      if product.listing_type.eql? 'variation'
        job_id = EbayVariationProductJob.set(wait: 5.mins).perform_later(listing_id: product.listing_id, sku: product.sku, quantity: product.quantity)
      elsif product.listing_type.eql? 'single'
        job_id = EbaySingleProductJob.set(wait: 5.mins).perform_later(listing_id: product.listing_id, quantity: product.quantity)
      end
    end
  end

end
