# frozen_string_literal: true

# converting response to products
class EbaySingleProductJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # @page_no = 1
    # @total_pages = 1
    @refresh_token = RefreshToken.where(channel: 'ebay').last
    credential = Credential.find_by(grant_type: 'refresh_token')
    remainaing_time = @refresh_token.access_token_expiry.localtime > DateTime.now
    generate_refresh_token(credential) if credential.present? && remainaing_time == false

    quantity = _args.last[:quantity] || _args.last['quantity']
    listing_id = _args.last[:listing_id] || _args.last['listing_id']

    return 'Product not found' if quantity.nil? || listing_id.nil?

    require 'net/http'
    require 'base64'
    require 'http'
    require 'json'
    require 'active_support/core_ext'
    require 'rexml/document'
    require 'builder'

    @xml_data = Builder::XmlMarkup.new
    @xml_data.instruct!
    @xml_data.ReviseItemRequest('xmlns' => 'urn:ebay:apis:eBLBaseComponents') do
      @xml_data.RequesterCredentials do
        @xml_data.eBayAuthToken @refresh_token.access_token.to_s
      end
      @xml_data.ErrorLanguage 'en_US'
      @xml_data.WarningLevel 'High'
      @xml_data.Item do
        @xml_data.ItemID listing_id
        @xml_data.DescriptionReviseMode 'Replace'
        @xml_data.Quantity quantity.to_i
      end
    end
    response = HTTP.post('https://api.ebay.com/ws/api.dll',
                          body: @xml_data.to_xml.split('<inspect/>').first,
                          headers: {
                            'X-EBAY-API-SITEID' => '2',
                            'X-EBAY-API-COMPATIBILITY-LEVEL' => '967',
                            'X-EBAY-API-CALL-NAME' => 'ReviseItem',
                            'X-EBAY-API-APP-NAME' => 'ChannelD-ChannelD-PRD-da28ec690-4a9f363c',
                            'X-EBAY-API-DEV-NAME' => '8a3c7cee-7507-45ca-bb47-22ffe194a94b',
                            'X-EBAY-API-CERT-NAME' => 'PRD-a28ec6908ea9-7c43-4fd9-be43-0e7d',
                            'X-EBAY-API-DETAIL-LEVEL' => '0'
                          })
    @xml_response_data = Nokogiri::XML(response.body)
    @data_xml_re = Hash.from_xml(@xml_response_data.to_xml)
    job_status(@data_xml_re['ReviseItemResponse'], listing_id, quantity)
  end

  def generate_refresh_token(credential)
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

  def job_status(response, listing_id, quantity)
    if (response['Ack'].eql? 'Failure') && (response['Errors']['ShortMessage'].include? 'Item level quantity will be ignored')
      # job_data = UpdateEbaySingleProductJob.perform_later(listing_id: listing_id , quantity: quantity)
      JobStatus.create(name: 'UpdateEbaySingleProductJob', status: 'retry',
                       arguments: { listing_id: listing_id, quantity: quantity, error: response['Errors']['ShortMessage'] }, perform_in: 600)
    elsif response['Ack'].eql? 'Failure'
      # self.class.perform_later(listing_id: listing_id , quantity: quantity, error: response['Errors']['LongMessage'])
      JobStatus.create(name: self.class.to_s, status: 'retry',
                       arguments: { listing_id: listing_id, quantity: quantity, error: response['Errors']['ShortMessage'] }, perform_in: 600)
    elsif response['Ack'].eql? 'Success'
      ChannelProduct.find_by(listing_id: listing_id).update(listing_type: 'single', item_quantity_changed: false)
    end
  end
end
