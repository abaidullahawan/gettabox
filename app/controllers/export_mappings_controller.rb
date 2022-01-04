# frozen_string_literal: true

# Export mapping used for exporting files
class ExportMappingsController < ApplicationController
  before_action :find_export_mapping, only: %i[edit update destroy]
  def index
    @product_export_mappings = ExportMapping.where(table_name: 'Product')
    @channel_order_export_mappings = ExportMapping.where(table_name: 'ChannelOrder')
    @channel_product_export_mappings = ExportMapping.where(table_name: 'ChannelProduct')
    @season_export_mappings = ExportMapping.where(table_name: 'Season')
    @category_export_mappings = ExportMapping.where(table_name: 'Category')
    @system_user_export_mappings = ExportMapping.where(table_name: 'SystemUser')
  end

  def new
    @export_mapping = ExportMapping.new
    @table_names = %w[Courier Product ChannelOrder ChannelProduct Season Category SystemUser]
  end

  def export_new; end

  def export_create
    @export_mapping = ExportMapping.new(table_name: params[:table_name], sub_type: params[:sub_type])
    mapping = {}
    params[:map_able].each do |col_name|
      mapping[col_name.to_s] = params[:"#{col_name}"]
    end
    @export_mapping.mapping_data = mapping
    if @export_mapping.save
      flash[:notice] = 'Export mapping created'
    else
      flash[:alert] = @export_mapping.errors.full_messages
    end
    redirect_to import_mappings_path
  end

  def edit
    @table_names = %w[Courier Product ChannelOrder ChannelProduct Season Category SystemUser]
    @column_names = @export_mapping.table_name.constantize.column_names
  end

  def get_table_columns
    @table_columns = params[:table_name].constantize.column_names
    respond_to do |format|
      format.json { render json: @table_columns }
    end
  end

  def create
    @export_mapping = ExportMapping.new(export_mapping_params)
    col_names = @export_mapping.table_name.constantize.column_names
    added_columns = []
    col_names.each do |col_name|
      added_columns.push(col_name) if params.include? col_name
    end
    @export_mapping.export_data = added_columns
    if @export_mapping.save
      redirect_to export_mappings_path
      flash[:notice] = 'Export Mapping Created.'
    else
      flash[:alert] = @export_mapping.errors.full_messages.to_s
      redirect_to export_mapping
    end
  end

  def update
    @export_mapping.update(export_mapping_params)
    col_names = @export_mapping.table_name.constantize.column_names
    added_columns = []
    col_names.each do |col_name|
      added_columns.push(col_name) if params.include? col_name
    end
    @export_mapping.update(export_data: added_columns)
    redirect_to export_mappings_path
    flash[:notice] = 'Export Mapping Updated.'
  end

  def destroy
    @export_mapping.destroy
    respond_to do |format|
      format.html { redirect_to export_mappings_path, notice: 'Export Mapping was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def find_export_mapping
    @export_mapping = ExportMapping.find(params[:id])
  end

  def export_mapping_params
    params.require(:export_mapping).permit(:table_name, :sub_type)
  end
end
