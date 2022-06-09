# frozen_string_literal: true

# amazon product quantity update
class UpdateAmazonProduct < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'amazon').last
    # sku = _args.last[:product] || _args.last['product']
    # quantity = _args.last[:quantity] || _args.last['quantity']
    products = _args&.last.try(:[], :products) || _args&.last.try(:[], 'products')
    return 'Products not found' if products.nil? || products.empty?

    remainaing_time = @refresh_token.access_token_expiry.localtime < DateTime.now
    generate_refresh_token if @refresh_token.present? && remainaing_time
    url = 'https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/documents'
    document = {
      "contentType" => "application/json; charset=UTF-8"
    }
    document_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return perform_later_queue(products, document_response[:error]) unless document_response[:status]

    result = upload_document(@refresh_token.access_token, document_response[:body]['url'], products)
    return perform_later_queue(products, result[:error]) unless result[:status]

    create_feed_response(document_response[:body], products)
  end

  def generate_refresh_token
    result = RefreshTokenService.amazon_refresh_token(@refresh_token)
    update_refresh_token(result[:body], @refresh_token) if result[:status]
  end

  def update_refresh_token(result, refresh_token)
    refresh_token.update(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds
    )
  end

  def upload_document(access_token, url, products)
    data = {
      "header" => {
        "sellerId" => "A292BGT65ET8F0",
        "version" => "2.0",
        "issueLocale" => "en_US"
      },
      "messages" =>
        products.each.with_index(1).map do |product, index|
          {
            "messageId" => index,
            "sku" => product.first,
            "operationType" => "PATCH",
            "productType" => "LUGGAGE",
            "patches" => [
              {
                "op" => "replace",
                "path" => "/attributes/fulfillment_availability",
                "value" => [
                  {
                    "fulfillment_channel_code" => "DEFAULT",
                    "quantity" => product.last.to_i
                  }
                ]
              }
            ]
          }
        end
    }
    result = put_document(data, url)
    return_response(result)
  end

  def put_document(data, url)
    # body = URI.encode_www_form(data)
    HTTParty.put(
      url.to_str,
      body: data.to_json,
      headers: { 'Content-Type' => 'application/json; charset=UTF-8' }
    )
  end

  def return_response(result)
    return { status: true, body: '' } if result.success?

    { status: false, error: result['error_description'] }
  end

  def create_feed_response(response, products)
    url = 'https://sellingpartnerapi-eu.amazon.com/feeds/2021-06-30/feeds'
    document = {
      "feedType" => "JSON_LISTINGS_FEED",
      "marketplaceIds" => [
        "A1F83G8C2ARO7P"
      ],
      "inputFeedDocumentId" => response['feedDocumentId']
    }
    feed_response = AmazonCreateReportService.create_report(@refresh_token.access_token, url, document)
    return perform_later_queue(products, feed_response[:error]) unless feed_response[:status]

    AmazonCheckFeedJob.perform_later(feed_id: feed_response[:body]['feedId'], records: products, job_status_id: @arguments.first.try(:[], :job_status_id))
  end

  def perform_later_queue(products, error)
    job_status = JobStatus.where(name: 'AmazonTrackingJob', status: 'inqueue').order(perform_in: :asc)&.first
    job = Sidekiq::ScheduledSet.new.find_job(job_status.job_id) if job_status.present?
    credential = Credential.find_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = DateTime.now > wait_time ? DateTime.now + 120.seconds : wait_time + 120.seconds
    credential.update(redirect_uri: nil, authorization: nil, created_at: wait_time)
    elapsed_seconds = wait_time - DateTime.now
    job.reschedule(DateTime.now + elapsed_seconds.seconds) if job.present?
    perform_in = job_status.present? ? job_status.perform_in : elapsed_seconds
    # job_data = self.class.set(wait: elapsed_seconds.seconds).perform_later(products: products, error: error)
    JobStatus.create(name: self.class.to_s, status: 'retry', arguments: { products: products, error: error }, perform_in: perform_in)
    job_status.update(perform_in: elapsed_seconds.seconds) if job.present? && job_status.present?
  end
end
