# frozen_string_literal: true

# tracking update on amazon
class EbayCompleteSaleJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @refresh_token = RefreshToken.where(channel: 'ebay').last
    credential = Credential.find_by(grant_type: 'refresh_token')
    remainaing_time = @refresh_token.access_token_expiry.localtime > DateTime.now
    update_refresh_token_call(credential) if @refresh_token.present? && remainaing_time == false

    order_ids = _args.last[:order_ids]
    orders = ChannelOrder.where(id: order_ids, channel_type: 'ebay')
    return 'Orders not found' unless orders.present?

    order_ids.each do |order_id|
      result = upload_document(@refresh_token.access_token, order_id)
    end
    # return result[:error] unless result[:status]

    # create_feed_response(document_response, order_ids)
  end

  def update_refresh_token_call(credential)
    result = RefreshTokenService.refresh_token_api(@refresh_token, credential)
    return update_refresh_token(result[:body], @refresh_token) if result[:status]

    puts (result[:error]).to_s
  rescue StandardError
    puts 'Please contact your administration for process'
  end

  def update_refresh_token(result, refresh_token)
    refresh_token.update(
      access_token: result['access_token'],
      access_token_expiry: DateTime.now + result['expires_in'].to_i.seconds
    )
  end

  def upload_document(access_token, order_id)
    xml_data = Builder::XmlMarkup.new
    xml_data.instruct!
    xml_data.CompleteSaleRequest('xmlns' => 'urn:ebay:apis:eBLBaseComponents') do
      xml_data.RequesterCredentials do
        xml_data.eBayAuthToken access_token
      end
      xml_data.ErrorLanguage 'en_US'
      xml_data.WarningLevel 'High'
      xml_data.OrderID order_id
      xml_data.Shipped true
    end
    response = HTTP.post('https://api.ebay.com/ws/api.dll',
                          body: xml_data.to_xml.split('<inspect/>').first,
                          headers: {
                            'X-EBAY-API-SITEID' => '3',
                            'X-EBAY-API-COMPATIBILITY-LEVEL' => '967',
                            'X-EBAY-API-CALL-NAME' => 'CompleteSale',
                          })
    xml_response_data = Nokogiri::XML(response.body)
    data_xml_re = Hash.from_xml(xml_response_data.to_xml)
  end

  # def return_response(result)
  #   return { status: true, body: result } if result.success?

  #   { status: false, error: result['error_description'] }
  # end
end
