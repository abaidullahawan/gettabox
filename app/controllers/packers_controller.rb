class PackersController < ApplicationController

  before_action :set_packer, only: %i[show edit update destroy]


  def index
    @packer = SystemUser.new
    @q = SystemUser.where(user_type: 'packer').ransack(params[:q])
    @packers = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@packers) if params[:export_csv].present?
    # @service = Service.new
    # @mail_service_rule = MailServiceRule.new
    # @courier_mappings = ExportMapping.where(table_name: 'Courier csv export')
  end

  # GET /services/1 or /services/1.json
  def show; end

  # GET /services/new
  def new
    @packer = SystemUser.new
  end

  # GET /services/1/edit
  def edit; end

  # POST /services or /services.json
  def create
    @packer = SystemUser.new(packer_params)
    @packer.user_type = 'packer'
    flash[:notice] = if @packer.save
                       'Packer was successfully created.'
                     else
                       @packer.errors.full_messages
                     end
    redirect_to packers_path
  end

  # PATCH/PUT /services/1 or /services/1.json
  def update
    if @packer.update(packer_params)
      flash[:notice] = 'packer was successfully updated.'
      redirect_to packers_path(@packer)
    else
      flash.now[:alert] = @packer.errors.full_messages
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
    redirect_to packers_path
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
    redirect_to packers_path
  end

  def archive
    @q = Service.only_deleted.ransack(params[:q])
    @services = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_packers_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && Service.only_deleted.find(params[:object_id]).really_destroy!
                       'service deleted successfully'
                     else
                       'service cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_packers_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_packer
    @packer = SystemUser.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def packer_params
    params.require(:system_user).permit(:name)
  end

end
