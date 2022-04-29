# frozen_string_literal: true

# amazon competative product price
class CompetitivePriceJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'amazon').last
    spreadsheet = _args.last[:spreadsheet]
    multifile_mapping_id = _args.last[:multifile_mapping_id]
    multifile = MultifileMapping.find_by(id: multifile_mapping_id)
    remainaing_time = @refresh_token.access_token_expiry.localtime < DateTime.now
    generate_refresh_token if @refresh_token.present? && remainaing_time

    spreadsheet = CSV.parse(spreadsheet, headers: true)
    spreadsheet.each do |row|
      asin = row.first.last
      url = "https://sellingpartnerapi-eu.amazon.com/products/pricing/v0/competitivePrice?MarketplaceId=A1F83G8C2ARO7P&ItemType=Asin&Asins=#{asin}"
      response = AmazonService.amazon_api(@refresh_token.access_token, url)

      prices = return_prices(response)
      row['LandedPrice'] = prices.first
      row['ListingPrice'] = prices.last
    end

    name = "multi-mapping--#{multifile.created_at.strftime('%d-%m-%Y @ %H:%M:%S')}"
    csv = CSV.open("/home/deploy/channeldispatch/current/tmp/#{name}", "wb") do |csv|
      csv << spreadsheet.headers
      spreadsheet.each{|row| csv << row}
    end
    multifile.update(download: true)
  rescue StandardError => e
    multifile.update(error: e, download: false)
  end

  def return_prices(response)
    return [response[:error]] unless response[:status]

    landed_price = []
    listing_price = []
    response[:body]['payload'].each do |payload|
      payload['Product']['CompetitivePricing']['CompetitivePrices'].each do |prices|
        landed_price << prices['Price']['LandedPrice']['Amount']
        listing_price << prices['Price']['ListingPrice']['Amount']
      end
    end
    landed_price = landed_price.first if landed_price.count.eql? 1
    listing_price = listing_price.first if listing_price.count.eql? 1
    [landed_price, listing_price]
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
end
