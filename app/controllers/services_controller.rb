# frozen_string_literal: true

# services belongs to couriers used for mailing
class ServicesController < ApplicationController
  include ImportExport

  before_action :set_service, only: %i[show edit update destroy]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  # GET /services or /services.json
  def index
    @q = Service.ransack(params[:q])
    @services = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@services) if params[:export_csv].present?
    @service = Service.new
    @mail_service_rule = MailServiceRule.new
    @courier_mappings = ExportMapping.where(table_name: 'Courier csv export')
  end

  # GET /services/1 or /services/1.json
  def show; end

  # GET /services/new
  def new
    @service = Service.new
  end

  # GET /services/1/edit
  def edit; end

  # POST /services or /services.json
  def create
    @service = Service.new(service_params)
    flash[:notice] = if @service.save
                       'Service was successfully created.'
                     else
                       'Unable to create Service.'
                     end
    redirect_to services_path
  end

  # PATCH/PUT /services/1 or /services/1.json
  def update
    if @service.update(service_params)
      flash[:notice] = 'Service was successfully updated.'
      redirect_to service_path(@service)
    else
      flash.now[:alert] = @service.errors.full_messages
      render :show
    end
  end

  # DELETE /services/1 or /services/1.json
  def destroy
    @service.destroy
    respond_to do |format|
      format.html { redirect_to services_url, notice: 'Service was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def export_csv(services)
    services = services.where(selected: true) if params[:selected]
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data services.to_csv, filename: "services-#{Date.today}.csv" }
    end
  end

  def import
    if @csv.present?
      @csv.delete('id')
      @csv.delete('created_at')
      @csv.delete('updated_at')
      csv_create_records(@csv)
      flash[:notice] = 'File Upload Successful!'
    end
    redirect_to services_path
  end

  def csv_create_records(csv)
    csv.each do |row|
      service = Service.with_deleted.create_with(name: row['name'], courier_id: row['courier_id'])
      .find_or_create_by(name: row['name'], courier_id: row['courier_id'])
      flash[:alert] = "#{service.errors.full_messages} at ID: #{service.id} , Try again " unless update_service(service, row)
    end
  end
  
  def update_service(service, row)
    service.update(row.to_hash)
  end

  def bulk_method
    redirect_to services_path
  end

  def archive
    @q = Service.only_deleted.ransack(params[:q])
    @services = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_services_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && Service.only_deleted.find(params[:object_id]).really_destroy!
                       'service deleted successfully'
                     else
                       'service cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_services_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_service
    @service = Service.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def service_params
    params.require(:service).permit(:name, :courier_id)
  end
end
