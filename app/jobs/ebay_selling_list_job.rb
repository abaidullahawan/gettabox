# frozen_string_literal: true

# get ebay product images
class EbaySellingListJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    refresh_token = RefreshToken.where(channel: 'ebay').last
    ebay_products = ChannelProduct.where(channel_type: 'ebay', item_image: nil)

    require 'net/http'
    require 'base64'
    require 'http'
    require 'json'
    require 'active_support/core_ext'
    require 'rexml/document'
    require 'builder'

    ebay_products.each do |product|
      response = get_product_response(product, refresh_token)
      sleep 5
      next unless response.status.to_s.include?('OK')

      @xml_response_data = Nokogiri::XML(response.body)
      @data_xml_re = Hash.from_xml(@xml_response_data&.to_xml)
      next if @data_xml_re['GetItemResponse'].nil? || @data_xml_re['GetItemResponse']['Item'].nil? || @data_xml_re['GetItemResponse']['Item']['PictureDetails'].nil?

      picture_details = @data_xml_re['GetItemResponse']['Item']['PictureDetails']
      item_image = picture_details['GalleryURL'] || picture_details['PictureURL']
      product.update(item_image: item_image)
    end
  end

  def get_product_response(product, refresh_token)
    xml_data = Builder::XmlMarkup.new
    xml_data.instruct!
    xml_data.GetItemRequest('xmlns' => 'urn:ebay:apis:eBLBaseComponents') do
      xml_data.RequesterCredentials do
        xml_data.eBayAuthToken refresh_token.access_token.to_s
      end
      xml_data.ErrorLanguage 'en_US'
      xml_data.WarningLevel 'High'
      xml_data.ItemID product.listing_id.to_s # Item ID
    end
    api_call(xml_data)
  end

  def api_call(xml_data)
    HTTP.post('https://api.ebay.com/ws/api.dll',
              body: xml_data.to_xml.split('<inspect/>').first,
              headers: {
                'X-EBAY-API-SITEID' => '3',
                'X-EBAY-API-COMPATIBILITY-LEVEL' => '967',
                'X-EBAY-API-CALL-NAME' => 'GetItem',
                'X-EBAY-API-APP-NAME' => 'ChannelD-ChannelD-PRD-da28ec690-4a9f363c',
                'X-EBAY-API-DEV-NAME' => '8a3c7cee-7507-45ca-bb47-22ffe194a94b',
                'X-EBAY-API-CERT-NAME' => 'PRD-a28ec6908ea9-7c43-4fd9-be43-0e7d',
                'X-EBAY-API-DETAIL-LEVEL' => '0'
              })
  end
end
