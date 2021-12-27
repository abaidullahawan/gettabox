# frozen_string_literal: true

# Export mapping used for exporting files
class ExportMappingsController < ApplicationController
  def index
    @product_export_mappings = ExportMapping.where(table_name: 'Product')
  end

  def new
    @table_names = ['Product', 'ChannelOrder']
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
      if params.include? col_name
        added_columns.push(col_name)
      end
    end
    @export_mapping.export_data = added_columns
    if @export_mapping.save
      redirect_to export_mappings_path
      flash[:notice] = 'Export Mapping Created.'
    else
      flash[:alert] = "#{@export_mapping.errors.full_messages}"
      redirect_to export_mapping
    end
  end

  private

  def export_mapping_params
    params.permit(:table_name, :sub_type)
  end

end
