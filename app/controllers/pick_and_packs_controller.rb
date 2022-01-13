class PickAndPacksController < ApplicationController

  include ImportExport

  before_action :set_packer, only: %i[show edit update destroy]
  before_action :klass_import, only: %i[import]
  before_action :klass_restore, only: %i[restore]

  def index
    @pick_and_pack = OrderBatch.new
    @q = OrderBatch.ransack(params[:q])
    @pick_and_packs = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@pick_and_packs) if params[:export_csv].present?
  end

  # GET /services/1 or /services/1.json
  def show
    @orders = @pick_and_pack.channel_orders
    respond_to do |format|
      format.js
    end
  end

  def show_order
    @order_batch = ChannelOrder.find(params[:id])
  end
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
    redirect_to pick_and_packs_path
  end

  # PATCH/PUT /services/1 or /services/1.json
  def update
    if @packer.update(packer_params)
      flash[:notice] = 'Packer was successfully updated.'
      redirect_to pick_and_packs_path(@packer)
    else
      flash.now[:alert] = @packer.errors.full_messages
      render :show
    end
  end

  # DELETE /services/1 or /services/1.json
  def destroy
    @packer.destroy
    respond_to do |format|
      format.html { redirect_to pick_and_packs_url, notice: 'Packer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def export_csv(pick_and_packs)
    pick_and_packs = pick_and_packs.where(selected: true) if params[:selected]
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data pick_and_packs.to_csv_packer, filename: "pick-and-packs-#{Date.today}.csv" }
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
    redirect_to pick_and_packs_path
  end

  def csv_create_records(csv)
    csv.each do |row|
      packer = SystemUser.with_deleted.create_with(name: row['name'])
      .find_or_create_by(name: row['name'])
      flash[:alert] = "#{packer.errors.full_messages} at ID: #{packer.id} , Try again " unless update_packer(packer, row)
    end
  end
  
  def update_pakcer(packer, row)
    packer.update(row.to_hash)
  end

  def bulk_method
    redirect_to pick_and_packs_path
  end

  def archive
    @q = SystemUser.only_deleted.ransack(params[:q])
    @pick_and_packs = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_pick_and_packs_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && SystemUser.only_deleted.find(params[:object_id]).really_destroy!
                       'Packer deleted successfully'
                     else
                       'Packer cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_pick_and_packs_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_packer
    @pick_and_pack = OrderBatch.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def packer_params
    params.require(:system_user).permit(:name)
  end

end
