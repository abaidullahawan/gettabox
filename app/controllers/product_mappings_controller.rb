class ProductMappingsController < ApplicationController
  include NewProduct

  before_action :authenticate_user!
  before_action :set_product_mapping, only: %i[ show update destroy ]
  before_action :refresh_token, only: %i[ index xml_file ]
  before_action :new_product, :product_load_resources, only: %i[ index ]

  def index
    @q = ChannelProduct.ransack(params[:q])
    @body = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    @matching_products = {}
    @body&.each do |item|
      matching = item.product_mapping&.product || Product.find_by("sku LIKE ?", "%#{item.item_sku}%")
      @matching_products[item.id] = matching if matching.present?
      end
    if params[:q].present? && params[:q][:status_eq] == '1'
      @matching_products = {}
      @body&.each do |item|
        matching = item.product_mapping&.product
        @matching_products[item.id] = matching if matching.present?
      end
    end
    if params[:product_mapping] == 'Ebay Production'
      ebay_production_call(@refresh_token) if @refresh_token.present?
    end
    if params[:export_csv].present?
      @products = ChannelProduct.all
      export_csv(@products)
    end
  end

  def show
  end

  def new
  end

  def xml_file
  end

  def edit
  end

  def create
    if params[:commit] == 'Map'
      product_id =  params[:anything][:product_id].empty? ? params[:anything][:mapped_product_id] : params[:anything][:product_id]
      if product_id.present?
        if product_id.to_i.to_s != product_id
          product_id =  Product.find_by(title: product_id).id
        end
        @product_mapping = ProductMapping.create!(channel_product_id: params[:anything]['channel_product_id'], product_id: product_id)
        ChannelProduct.find(params[:anything]['channel_product_id']).status_mapped! if @product_mapping.present?
        flash[:notice] = 'Product mapped successfully'
        redirect_to product_mappings_path
      else
        flash[:alert] = 'Please select product to map'
        redirect_to product_mappings_path
      end
    end
    if params[:commit] == 'Un-map'
      product_id = params[:anything]['mapped_product_id'] || params['mapped_product_id']
      @product_mapping = ProductMapping.find_by(channel_product_id: params[:anything]['channel_product_id'], product_id: product_id)
      if @product_mapping&.destroy
        ChannelProduct.find(params[:anything]['channel_product_id']).status_unmapped!
        flash[:notice] = 'Product Un-mapped successfully'
        redirect_to product_mappings_path
      else
        flash[:notice] = 'Product cannot be Un-mapped'
        redirect_to product_mappings_path
      end
    end
    if params[:commit] == 'Create'
      cd = ChannelProduct.find(params['channel_product_id'])
      @product = Product.new(product_mapping_params)
      first_or_create_category
      if @product&.save
        ProductMapping.create(channel_product_id: cd.id, product_id: @product.id)
        url = URI.parse(cd.product_data['ListingDetails']['ViewItemURL'])
        filename = File.basename(url.path)
        begin
          file = URI.open(url)
          @product.photo.attach(io: file, filename: filename) if file.present?
          flash[:notice] = 'Product created successfully'
          redirect_to product_mappings_path
        rescue OpenURI::HTTPError => e
          flash[:alert] = 'Product created! Cannot upload image'
          redirect_to product_mappings_path
        end
      else
        flash[:alert] = 'Product cannot be created!'
        redirect_to product_mappings_path
      end
    end
  end

  def export_csv(products)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data csv_export(products), filename: "ChannelProducts-#{Date.today}.csv" }
    end
  end

  def update
  end

  def destroy
  end

  private

    def csv_export(products)
      attributes = ChannelProduct.column_names.excluding('created_at', 'updated_at')
      CSV.generate(headers: true) do |csv|
        csv << attributes
        ChannelProduct.all.each do |products|
          csv << attributes.map{ |attr| products.send(attr) }
        end
      end
    end

    def product_mapping_params
      params.
      require(:product).
      permit( :sku,
              :title,
              :photo,
              :total_stock,
              :fake_stock,
              :pending_orders,
              :allocated_orders,
              :available_stock,
              :length,
              :width,
              :height,
              :weight,
              :pack_quantity,
              :cost_price,
              :gst,
              :vat,
              :hst,
              :pst,
              :qst,
              :minimum,
              :maximum,
              :optimal,
              :category_id,
              :product_type,
              :season_id,
              :description,
              barcodes_attributes:
              [ :id,
                :title,
                :_destroy
              ],
              product_suppliers_attributes:
              [ :id,
                :system_user_id,
                :product_cost,
                :product_sku,
                :product_vat,
                :_destroy
              ],
              multipack_products_attributes:
              [ :id,
                :product_id,
                :child_id,
                :quantity,
                :_destroy
              ]
      )
    end

    def product_invetory_call(refresh_token)
      require 'uri'
      require 'net/http'

      url = ('https://api.sandbox.ebay.com/sell/inventory/v1/inventory_item?offset=0')
      params = { :limit => 10, :page => 3 }
      headers = { 'authorization' => "Bearer <#{refresh_token.access_token}>",
                  'accept-language' => 'en-US'}
      uri = URI(url)
      request = Net::HTTP.get_response(uri, headers)

      body = JSON.parse(request.body)

      if body["inventoryItems"].present?
        body["inventoryItems"].each do |item|
          ChannelProduct.where(channel_type: 'ebay', product_data: item).first_or_create
        end
      end
      respond_to do |format|
        format.html
      end
    end

    def ebay_production_call(refresh_token)

      @page_no = 1
      @total_pages = 1

      require 'net/http'
      require 'base64'
      require 'http'
      require 'json'
      require 'active_support/core_ext'
      require "rexml/document"
      require 'builder'

      loop do
        @xml_data = Builder::XmlMarkup.new()
        @xml_data.instruct!
        @xml_data.GetMyeBaySellingRequest("xmlns" => "urn:ebay:apis:eBLBaseComponents"){
          @xml_data.RequesterCredentials{
            @xml_data.eBayAuthToken "#{refresh_token.access_token}"
          }
          @xml_data.ErrorLanguage "en_US"
          @xml_data.WarningLevel "High"
          @xml_data.ActiveList{
            @xml_data.Sort "TimeLeft"
            @xml_data.Pagination{
              @xml_data.PageNumber "#{@page_no}"
            }
          }
        }
        response = HTTP.post("https://api.ebay.com/ws/api.dll",
          :body => @xml_data.to_xml.split("<inspect/>").first,
          :headers => {
            'X-EBAY-API-SITEID' => '3',
            'X-EBAY-API-COMPATIBILITY-LEVEL' => '967',
            'X-EBAY-API-CALL-NAME' => 'GetMyeBaySelling',
            'X-EBAY-API-APP-NAME' => 'ChannelD-ChannelD-PRD-da28ec690-4a9f363c',
            'X-EBAY-API-DEV-NAME' => '8a3c7cee-7507-45ca-bb47-22ffe194a94b',
            'X-EBAY-API-CERT-NAME' => 'PRD-a28ec6908ea9-7c43-4fd9-be43-0e7d',
            'X-EBAY-API-DETAIL-LEVEL' => '0'
          }
        )
        @xml_response_data = Nokogiri::XML(response.body)
        @data_xml_re = Hash.from_xml(@xml_response_data.to_xml)
        @total_pages = @data_xml_re['GetMyeBaySellingResponse']['ActiveList']['PaginationResult']['TotalNumberOfPages'].to_i
        ChannelResponseData.create(channel: "ebay", response: @data_xml_re, api_url: "https://api.ebay.com/ws/api.dll", api_call: "GetMyeBaySelling", status: "panding")
        @page_no += 1
        if @page_no > @total_pages
          break
        end
      end
      CreateChannelProductJob.perform_later
    end

end
