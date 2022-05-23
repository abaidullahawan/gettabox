# frozen_string_literal: true

# converting response to products
class CreateChannelProductResponseJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    @page_no = 1
    @total_pages = 1
    refresh_token = RefreshToken.where(channel: 'ebay').last

    require 'net/http'
    require 'base64'
    require 'http'
    require 'json'
    require 'active_support/core_ext'
    require 'rexml/document'
    require 'builder'

    loop do
      @xml_data = Builder::XmlMarkup.new
      @xml_data.instruct!
      @xml_data.GetMyeBaySellingRequest('xmlns' => 'urn:ebay:apis:eBLBaseComponents') do
        @xml_data.RequesterCredentials do
          @xml_data.eBayAuthToken refresh_token.access_token.to_s
        end
        @xml_data.ErrorLanguage 'en_US'
        @xml_data.WarningLevel 'High'
        @xml_data.ActiveList do
          @xml_data.Sort 'TimeLeft'
          @xml_data.Pagination do
            @xml_data.PageNumber @page_no.to_s
          end
        end
      end
      response = HTTP.post('https://api.ebay.com/ws/api.dll',
                           body: @xml_data.to_xml.split('<inspect/>').first,
                           headers: {
                             'X-EBAY-API-SITEID' => '3',
                             'X-EBAY-API-COMPATIBILITY-LEVEL' => '967',
                             'X-EBAY-API-CALL-NAME' => 'GetMyeBaySelling',
                             'X-EBAY-API-APP-NAME' => 'ChannelD-ChannelD-PRD-da28ec690-4a9f363c',
                             'X-EBAY-API-DEV-NAME' => '8a3c7cee-7507-45ca-bb47-22ffe194a94b',
                             'X-EBAY-API-CERT-NAME' => 'PRD-a28ec6908ea9-7c43-4fd9-be43-0e7d',
                             'X-EBAY-API-DETAIL-LEVEL' => '0'
                           })
      @xml_response_data = Nokogiri::XML(response.body)
      @data_xml_re = Hash.from_xml(@xml_response_data.to_xml)
      @total_pages = @data_xml_re['GetMyeBaySellingResponse']['ActiveList'].try(:[], 'PaginationResult').try(:[], 'TotalNumberOfPages')
                     .to_i
      ChannelResponseData.create(channel: 'ebay', response: @data_xml_re, api_url: 'https://api.ebay.com/ws/api.dll',
                                 api_call: 'GetMyeBaySelling', status: 'pending')
      @page_no += 1
      break if @page_no > @total_pages
    end
    job_data = CreateChannelProductJob.perform_later
    JobStatus.create(job_id: job_data.job_id, name: 'CreateChannelProductJob', status: 'Queued')
    job_data = EbaySellingListJob.perform_later
    JobStatus.create(job_id: job_data.job_id, name: 'EbaySellingListJob', status: 'Queued')
  end
end
