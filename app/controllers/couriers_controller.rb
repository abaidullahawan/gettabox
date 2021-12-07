class CouriersController < ApplicationController
  include ImportExport

  before_action :set_courier, only: %i[show edit update destroy]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  # GET /couriers or /couriers.json
  def index
    @q = Courier.ransack(params[:q])
    @couriers = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@couriers) if params[:export_csv].present?
    @courier = Courier.new
  end

  # GET /couriers/1 or /couriers/1.json
  def show; end

  # GET /couriers/new
  def new
    @courier = Courier.new
  end

  # GET /couriers/1/edit
  def edit; end

  # POST /couriers or /couriers.json
  def create
    @courier = Courier.new(courier_params)
    flash[:notice] = if @courier.save
                       'Courier was successfully created.'
                     else
                       'Unable to create Courier.'
                     end
    redirect_to couriers_path
  end

  # PATCH/PUT /couriers/1 or /couriers/1.json
  def update
    respond_to do |format|
      if @courier.update(courier_params)
        format.html { redirect_to @courier, notice: 'Courier was successfully updated.' }
        format.json { render :show, status: :ok, location: @courier }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @courier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /couriers/1 or /couriers/1.json
  def destroy
    @courier.destroy
    respond_to do |format|
      format.html { redirect_to couriers_url, notice: 'Courier was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def export_csv(couriers)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data couriers.to_csv, filename: "couriers-#{Date.today}.csv" }
    end
  end

  def import
    if @csv.present?
      @csv.delete('id')
      @csv.delete('created_at')
      @csv.delete('updated_at')
      csv_create_records(@csv)
      flash[:alert] = 'File Upload Successful!'
    end
    redirect_to couriers_path
  end

  def bulk_method
    redirect_to couriers_path
  end

  def archive
    @q = Courier.only_deleted.ransack(params[:q])
    @couriers = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_couriers_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && Courier.only_deleted.find(params[:object_id]).really_destroy!
                       'courier deleted successfully'
                     else
                       'courier cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_couriers_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_courier
    @courier = Courier.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def courier_params
    params.require(:courier).permit(:name)
  end
end
