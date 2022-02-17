# frozen_string_literal: true

# Product Locations
class ProductLocationsController < ApplicationController
  def index
    @product_location = ProductLocation.all
  end

  def create
    file = params[:file]
    product_location_mapping = []
    file_type = file.present? ? file.path.split('.').last.to_s.downcase : ''
    if file.present? && (file_type.include? 'csv')
      spreadsheet = open_spreadsheet(file)
      csv_text = spreadsheet.split("\n")
      csv_text.each do |row|
        product_location_mapping << ProductLocation.find_or_initialize_by(location: row)
      end
      ProductLocation.import product_location_mapping, on_duplicate_key_ignore: true
    else
      flash[:alert] = 'Try again file not match'
    end
    flash[:notice] = 'Product location mapping was successfully created.'
    redirect_to request.referer
  end

  def edit
    @product_location = ProductLocation.find(params[:id])
  end

  def update
    @product_location = ProductLocation.find(params[:id])
    if @product_location.update(location: params["product_location"][:location])
      flash[:notice] = 'Location was updated successfully.'
      redirect_to product_locations_path
    else
      redirect_to product_locations_path
    end
  end

  def destroy
    @location = ProductLocation.find(params[:id])
    @location.destroy
    flash[:notice] = 'Location was deleted successfully.'
    redirect_to product_locations_path
  end

  private

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv' then  File.read(file).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
    when '.xls' then  Roo::Excel.new(file.path, packed: nil, file_warning: :ignore)
    when '.xlsx' then Roo::Excelx.new(file.path, packed: nil, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
