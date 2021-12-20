# frozen_string_literal: true

# Import mapping used for importing files
class ImportMappingsController < ApplicationController
  before_action :set_import_mapping, only: %i[show edit update destroy]

  # GET /import_mappings or /import_mappings.json
  def index
    @product = Product.new
    @import_mappings = ImportMapping.where(mapping_type: nil)
    @multi_mappings = ImportMapping.where(mapping_type: 'dual')
  end

  # GET /import_mappings/1 or /import_mappings/1.json
  def show; end

  # GET /import_mappings/new
  def new
    @import_mapping = ImportMapping.new
    @table_names = ['Product']
  end

  # GET /import_mappings/1/edit
  def edit
    @table_names = ['Product']
  end

  def file_mapping
    file = params[:file_1]
    file2 = params[:file_2]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      csv_text1 = File.read(file)
      csv1 = CSV.parse(csv_text1, headers: true)
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    if file2.present? && file2.path.split('.').last.to_s.downcase == 'csv'
      csv_text2 = File.read(file2)
      csv2 = CSV.parse(csv_text2, headers: true)
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    redirect_to file_mapping_page_path(csv1: csv1.headers, csv2: csv2.headers)
  end

  def file_mapping_page
    @csv1_headers = []
    @csv2_headers = []
    params[:csv1].each do |header|
      @csv1_headers.push(header.gsub(' ', '_'))
    end
    params[:csv2].each do |header|
      @csv2_headers.push(header.gsub(' ', '_'))
    end
  end

  # POST /import_mappings or /import_mappings.json
  def create
    mapping = {}
    if params[:mapping_type] == 'dual'
      @import_mapping = ImportMapping.new(table_data: params[:table_data].split(' '), header_data: params[:header_data].split(' '), mapping_data: params[:mapping_data], mapping_type: params[:mapping_type])
      @import_mapping.table_data.each do |data|
        mapping[data.to_s] = params[:"#{data}"]
      end
      @import_mapping.mapping_data = mapping
    else
      Product.column_names.each do |col_name|
        mapping[col_name.to_s] = params[:"#{col_name}"]
      end
      @import_mapping = ImportMapping.new(table_name: params[:table_data], mapping_data: mapping, sub_type: params[:sub_type], table_data: params[:header_data].split(' '), header_data: params[:header_data].split(' '))
    end
    respond_to do |format|
      if @import_mapping.save
        format.html { redirect_to import_mappings_path, notice: 'Import mapping was successfully created.' }
        format.json { render :index, status: :created, location: @import_mapping }
      else
        format.json { render json: @import_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /import_mappings/1 or /import_mappings/1.json
  def update
    mapping = {}
    Product.column_names.each do |col_name|
      mapping[col_name.to_s] = params[:"#{col_name}"]
    end
    @import_mapping = ImportMapping.update(mapping_data: mapping, sub_type: params[:sub_type])
    respond_to do |format|
      format.html { redirect_to import_mappings_path, notice: 'Import mapping was successfully updated.' }
      format.json { render :show, status: :ok, location: @import_mapping }
    end
  end

  # DELETE /import_mappings/1 or /import_mappings/1.json
  def destroy
    @import_mapping.destroy
    respond_to do |format|
      format.html { redirect_to import_mappings_url, notice: 'Import mapping was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def multi_file_mapping
    return unless params[:file_1].present? && params[:file_2].present?

    file1 = params[:file_1]
    file2 = params[:file_2]
    file_type1 = file1.present? ? file1.path.split('.').last.to_s.downcase : ''
    file_type2 = file2.present? ? file2.path.split('.').last.to_s.downcase : ''
    attributes = ImportMapping.find(params[:mapping_id]).table_data
    if file1.present? && file2.present? && (file_type1.include? 'csv') || (file_type1.include? 'xlsx') && (file_type2.include? 'csv') || (file_type2.include? 'xlsx')
      spreadsheet1 = open_spreadsheet(file1)
      spreadsheet2 = open_spreadsheet(file2)
      deleteable = ImportMapping.find(params[:mapping_id]).mapping_data.select {|_,v|  v.nil? }
      matchable = ImportMapping.find(params[:mapping_id]).mapping_data.select { |_, v| v.present? && v != '' }
      deleteable.each do |del_data|
        spreadsheet1.delete(del_data[0])
        spreadsheet2.delete(del_data[0])
      end
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        spreadsheet1.each do |record1|
          spreadsheet2.each do |record2|
            matchable.each do |matched|
              if record1[matched[0].gsub('_',' ')] == record2[matched[1].gsub('_', ' ')]
                row = record1.values_at([matched[0].gsub('_',' ')])
                csv << row
              end
            end
          end
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "orders-#{Date.today}.csv" }
      end
    else
      flash[:alert] = 'Try again file not match'
      redirect_to import_mappings_path
    end
  end

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv' then CSV.parse(File.read(file.path).force_encoding('ISO-8859-1').encode('utf-8', replace: nil), headers: true)
    when '.xls' then  Roo::Excel.new(file.path, packed: nil, file_warning: :ignore)
    when '.xlsx' then Roo::Excelx.new(file.path, packed: nil, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_import_mapping
    @import_mapping = ImportMapping.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def import_mapping_params
    params.require(:import_mapping).permit(:table_name, :mapping_data, :sub_type)
  end
end
