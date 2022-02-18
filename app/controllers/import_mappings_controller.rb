# frozen_string_literal: true

# Import mapping used for importing files
class ImportMappingsController < ApplicationController
  before_action :set_import_mapping, only: %i[show edit update destroy]

  # GET /import_mappings or /import_mappings.json
  def index
    @courier_csv_export = ChannelOrder.new
    @product = Product.new
    @order = ChannelOrder.new
    @channel_product = ChannelProduct.new
    @tracking = Tracking.new
    @product_mappings = ImportMapping.where(table_name: 'Product')
    @order_mappings = ImportMapping.where(table_name: 'Channel Order')
    @channel_product_mappings = ImportMapping.where(table_name: 'Channel Product')
    @multi_mappings = ImportMapping.where(mapping_type: 'dual')
    @tracking_mappings = ImportMapping.where(table_name: 'Tracking')
    @consolidation = ImportMapping.new
    # index export_mapping
    @product_export_mappings = ExportMapping.where(table_name: 'Product')
    @channel_order_export_mappings = ExportMapping.where(table_name: 'ChannelOrder')
    @channel_product_export_mappings = ExportMapping.where(table_name: 'ChannelProduct')
    @season_export_mappings = ExportMapping.where(table_name: 'Season')
    @category_export_mappings = ExportMapping.where(table_name: 'Category')
    @system_user_export_mappings = ExportMapping.where(table_name: 'SystemUser')
    @courier_csv_exports = ExportMapping.where(table_name: 'Courier csv export')
    @consolidations = ImportMapping.where(table_name: 'consolidation')
    @multifile_mapping = Dir[Rails.root.join('tmp/*').to_s]
    @multifile_mapping_filename = MultifileMapping.all
  end

  # GET /import_mappings/1 or /import_mappings/1.json
  def show; end

  # GET /import_mappings/new
  def new
    @import_mapping = ImportMapping.new
    @table_names = ['Product', 'Channel Order', 'Channel Product', 'Tracking']
  end

  def export_new_consolidation
    @import_mapping = ImportMapping.new
  end

  def export_consolidation
    params_data = params[:table_data].split('_')
    data_arr = []
    params_data.each do |data|
      data_arr.push( data => params[data] )
    end
    ImportMapping.create(header_data: params_data, mapping_type: params[:consolidation_field], table_name: 'consolidation', data_to_print: data_arr, sub_type: params[:description])
    redirect_to import_mappings_path
  end

  # GET /import_mappings/1/edit
  def edit
    @table_names = ['Product', 'Channel Order', 'Channel Product', 'Tracking']
  end

  def file_mapping
    file = params[:file_1]
    file2 = params[:file_2]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      csv_text1 = File.read(file).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
      csv1 = CSV.parse(csv_text1, headers: true)
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    if file2.present? && file2.path.split('.').last.to_s.downcase == 'csv'
      csv_text2 = File.read(file2).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
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
      @csv1_headers.push(header.gsub('_', ' ').gsub(' ', '_'))
    end
    params[:csv2].each do |header|
      @csv2_headers.push(header.gsub('_', ' ').gsub(' ', '_'))
    end
    @csv1_headers = @csv1_headers.reject { |c| c.empty? }
    @csv2_headers = @csv2_headers.reject { |c| c.empty? }
  end

  # POST /import_mappings or /import_mappings.json
  def create
    mapping = {}
    if params[:mapping_type] == 'dual'
      header_to_print = []
      @import_mapping = ImportMapping.new(mapping_rule: params[:rules], sub_type: params[:sub_type], table_data: params[:table_data].split(' '), header_data: params[:header_data].split(' '), mapping_data: params[:mapping_data], mapping_type: params[:mapping_type])
      @import_mapping.table_data.each do |data|
        mapping[data.to_s] = params[:"#{data}"]
      end
      @import_mapping.mapping_data = mapping
      if params[:headers_1].present?
        params[:headers_1].each do |header_1|
          header_to_print.push(header_1)
        end
      end
      if params[:headers_2].present?
        params[:headers_2].each do |header_2|
          header_to_print.push(header_2)
        end
      end
      @import_mapping.data_to_print = header_to_print if header_to_print.present?
    else
      @table_name = params[:table_name]
      @table_name.parameterize.underscore.classify.constantize.column_names.each do |col_name|
        mapping[col_name.to_s] = params[:"#{col_name}"]
      end
      @import_mapping = ImportMapping.new(table_name: params[:table_name], mapping_data: mapping,
                                          sub_type: params[:sub_type], table_data: params[:header_data].split(' '),
                                          header_data: params[:header_data].split(' '))
    end
    respond_to do |format|
      if @import_mapping.save
        format.html { redirect_to import_mappings_path, notice: 'Import mapping was successfully created.' }
        format.json { render :index, status: :created, location: @import_mapping }
      else
        format.html { redirect_to import_mappings_path, notice: @import_mapping.errors.full_messages }
        format.json { render json: @import_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /import_mappings/1 or /import_mappings/1.json
  def update
    mapping = {}
    if params[:import_mapping][:mapping_type] == 'dual'
      header_to_print = []
      @import_mapping.update(mapping_rule: params[:rules], sub_type: params[:import_mapping][:sub_type], mapping_data: params[:mapping_data])
      @import_mapping.table_data.each do |data|
        mapping[data.to_s] = params[:"#{data}"]
      end
      @import_mapping.update(mapping_data: mapping)
      if params[:headers_1].present?
        params[:headers_1].each do |header_1|
          header_to_print.push(header_1)
        end
      end
      if params[:headers_2].present?
        params[:headers_2].each do |header_2|
          header_to_print.push(header_2)
        end
      end
      @import_mapping.update(data_to_print: header_to_print) if header_to_print.present?
    else
      @table_name = params[:import_mapping][:table_name]
      @table_name.parameterize.underscore.classify.constantize.column_names.each do |col_name|
        mapping[col_name.to_s] = params[:"#{col_name}"]
      end
      @import_mapping.update(table_name: params[:import_mapping][:table_name], mapping_data: mapping,
                                          sub_type: params[:import_mapping][:sub_type])
    end
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

  def consolidation_mapping
    mapping = ImportMapping.find_by(id: params[:import_mapping][:consolidation_id])
    file = params[:import_mapping][:file]
    mapping_hash = []
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      to_be_ignored = ['id', 'user_type', 'selected','created_at', 'updated_at']
      csv_text = File.read(file)
      csv_headers = CSV.parse(csv_text, headers: true).headers
      csv_data = CSV.parse(csv_text, headers: true)
      csv_data.each do |data|
        mapping_hash << data.to_h
      end

      headers = []
      mapping[:data_to_print].each do |val|
        if(val.values[0] != nil)
          headers << val.keys[0]
        end
      end
      csv_data_export = CSV.generate(headers: true) do |csv|
        csv << headers
        mapping_hash.group_by{|h| h[mapping[:mapping_type]]}.values.each do |value|
          row = []
          mapping[:data_to_print].each do |val|
            case val.to_a[0][1]
            when "Merge"
              row << value.map{ |a| a[val.to_a[0][0]]}
            when "Sum"
              row << value.map{ |a| a[val.to_a[0][0]].to_i}.sum
            when "Consolidation"
              row << value.map{ |a| a[val.to_a[0][0]]}.uniq.first
            end
          end
          csv << row
        end
      end
      request.format = "csv"
      respond_to do |format|
        format.csv {send_data csv_data_export, filename: "Consolidation-#{Date.today}.csv"}
      end
    else
      flash[:alert] = 'Please use csv file'
      redirect_to import_mappings_path
    end
  end

  def multi_file_mapping
    file1 = params[:file_1]
    file2 = params[:file_2]
    file_type1 = file1.present? ? file1.path.split('.').last.to_s.downcase : ''
    file_type2 = file2.present? ? file2.path.split('.').last.to_s.downcase : ''
    mapping = ImportMapping.find(params[:mapping_id])
    if file1.present? && file2.present? && (file_type1.include? 'csv') && (file_type2.include? 'csv')
      spreadsheet1 = open_spreadsheet(file1)
      spreadsheet2 = open_spreadsheet(file2)
      @multifile_mapping = MultifileMapping.create(file1: file1.original_filename, file2: file2.original_filename, download: 0)
      MultiFileMappingJob.perform_later(spreadsheet1: spreadsheet1, spreadsheet2: spreadsheet2, mapping: mapping, multifile_mapping_id: @multifile_mapping.id)
      flash[:notice] = 'Job added successfully!'
    else
      flash[:alert] = 'Try again file not match'
    end
    redirect_to import_mappings_path
  end

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv' then  File.read(file).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
    when '.xls' then  Roo::Excel.new(file.path, packed: nil, file_warning: :ignore)
    when '.xlsx' then Roo::Excelx.new(file.path, packed: nil, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def tracking_file
    return unless params[:tracking][:file].present?

    file = params[:tracking][:file]
    file_type = file.present? ? file.path.split('.').last.to_s.downcase : ''
    if file.present? && (file_type.include? 'csv') || (file_type.include? 'xlsx')
      spreadsheet = open_spreadsheet(file)
      @header = spreadsheet.headers
      @data = []
      @import_mapping = ImportMapping.new
      @db_names = Tracking.column_names
      redirect_to new_import_mapping_path(db_columns: @db_names, header: @header, import_mapping: @import_mapping)
    else
      flash[:alert] = 'Try again file not match'
    end
  end

  def courier_csv_export
    file = params[:channel_order][:file]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      to_be_ignored = ['id', 'user_type', 'selected','created_at', 'updated_at']
      csv_text = File.read(file)
      csv_headers = CSV.parse(csv_text, headers: true).headers
      column_names = (ChannelOrder.column_names + ChannelOrderItem.column_names.excluding(to_be_ignored) +
                      MailServiceLabel.column_names.excluding(to_be_ignored) + SystemUser.column_names
                      .excluding(to_be_ignored) + Address.column_names.excluding(to_be_ignored))
      redirect_to export_new_export_mappings_path(column_names: column_names, csv_headers: csv_headers)
      # export_mapping = ExportMapping.new(table_name: 'Order', sub_type: 'Courier csv export', export_data: csv_headers)
      # if export_mapping.save
      #   flash[:notice] = 'Export Mapping created'
      #   redirect_to import_mappings_path
      # else
      #   flash[:alert] = export_mapping.errors.full_messages
      #   render 'edit'
      # end
    else
      flash[:alert] = 'Please use csv file'
      redirect_to import_mappings_path
    end
  end

  def consolidation_tool

    file = params[:file]
    file_type = file.present? ? file.path.split('.').last.to_s.downcase : ''
    if file.present? && (file_type.include? 'csv') || (file_type.include? 'xlsx')
      spreadsheet = open_spreadsheet(file)
      @header = spreadsheet.headers
      @data = []
      @import_mapping = ImportMapping.new

      @db_names = ['Consolidation', 'Merge', 'Sum']
      redirect_to export_new_consolidation_path(db_columns: @header, header: @db_names, import_mapping: @import_mapping)
    else
      flash[:alert] = 'Try again file not match'
    end
  end

  def download
    if params[:download].eql? 'true'
      send_file(
        params[:url],
        filename: "your_custom_file_name.csv",
        type: "csv"
      )
    else
      File.delete(params[:url])
      MultifileMapping.find_by(id: params[:id]).destroy
      flash[:notice] = 'File deleted!'
      redirect_to import_mappings_path
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
