# frozen_string_literal: true

# converting response to products
class UpdateChannelQuantity < ApplicationJob
  queue_as :default

  def perform(*_args)
    amazon_products = ChannelProduct.where(item_quantity_changed: true, channel_type: 'amazon').pluck(:item_sku, :channel_quantity)
    ebay_products = ChannelProduct.where(item_quantity_changed: true, channel_type: 'ebay')

    calling_amazon_jobs(amazon_products) unless amazon_products.nil?
    calling_ebay_jobs(ebay_products) unless ebay_products.nil?
  end

  def calling_amazon_jobs(products)
    products.each_slice(20) do |chunk|
      perform_later_queue(chunk, 'Updating in chunks')
    end
  end

  def perform_later_queue(products, message)
    job_status = JobStatus.where(name: 'AmazonTrackingJob', status: 'inqueue').order(perform_in: :asc)&.first
    job = Sidekiq::ScheduledSet.new.find_job(job_status.job_id) if job_status.present?
    credential = Credential.find_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = Time.zone.now.no_dst > wait_time ? Time.zone.now.no_dst + 120.seconds : wait_time + 120.seconds
    credential.update(redirect_uri: nil, authorization: nil, created_at: wait_time)
    elapsed_seconds = wait_time - Time.zone.now.no_dst
    job.reschedule(Time.zone.now.no_dst + elapsed_seconds.seconds) if job.present?
    perform_in = job_status.present? ? job_status.perform_in : elapsed_seconds
    # job_data = self.class.set(wait: elapsed_seconds.seconds).perform_later(products: products, error: error)
    JobStatus.create(name: 'UpdateAmazonProduct', status: 'inqueue', arguments: { products: products, message: message }, perform_in: perform_in)
    job_status.update(perform_in: elapsed_seconds.seconds) if job.present? && job_status.present?
  end

  def calling_ebay_jobs(products)
    products.each.with_index(1) do |product, index|
      if product.listing_type.eql? 'variation'
        JobStatus.create(name: 'EbayVariationProductJob', status: 'inqueue', arguments: { listing_id: product.listing_id, sku: product.item_sku, quantity: product.channel_quantity }, perform_in: index * 10)
        # job_id = EbayVariationProductJob.perform_later(listing_id: product.listing_id, sku: product.sku, quantity: product.quantity)
      elsif product.listing_type.eql? 'single'
        JobStatus.create(name: 'EbaySingleProductJob', status: 'inqueue', arguments: { listing_id: product.listing_id, quantity: product.channel_quantity }, perform_in: index * 10)
        # job_id = EbaySingleProductJob.perform_later(listing_id: product.listing_id, quantity: product.quantity)
      end
    end
  end
end
