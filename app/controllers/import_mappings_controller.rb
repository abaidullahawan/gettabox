class ImportMappingsController < ApplicationController
  before_action :set_import_mapping, only: %i[ show edit update destroy ]

  # GET /import_mappings or /import_mappings.json
  def index
    @import_mappings = ImportMapping.all
  end

  # GET /import_mappings/1 or /import_mappings/1.json
  def show
  end

  # GET /import_mappings/new
  def new
    @import_mapping = ImportMapping.new
    @table_names = ['Product']
  end

  # GET /import_mappings/1/edit
  def edit
  end

  # POST /import_mappings or /import_mappings.json
  def create
    mapping = { "#{[params[:header_fields]]}": "#{params[:table_fields]}" }
    @import_mapping = ImportMapping.new(table_name: params[:table_name], mapping_data: mapping)
    respond_to do |format|
      if @import_mapping.save
        format.html { redirect_to @import_mapping, notice: "Import mapping was successfully created." }
        format.json { render :show, status: :created, location: @import_mapping }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @import_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /import_mappings/1 or /import_mappings/1.json
  def update
    respond_to do |format|
      if @import_mapping.update(import_mapping_params)
        format.html { redirect_to @import_mapping, notice: "Import mapping was successfully updated." }
        format.json { render :show, status: :ok, location: @import_mapping }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @import_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /import_mappings/1 or /import_mappings/1.json
  def destroy
    @import_mapping.destroy
    respond_to do |format|
      format.html { redirect_to import_mappings_url, notice: "Import mapping was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_import_mapping
      @import_mapping = ImportMapping.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def import_mapping_params
      params.require(:import_mapping).permit(:table_name, :mapping_data)
    end
end
