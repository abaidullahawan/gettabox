class PickAndPacksController < ApplicationController
  include ImportExport

  before_action :set_packer, only: %i[show edit update destroy]
  before_action :klass_import, only: %i[import]
  # before_action :klass_restore, only: %i[restore]

  def index
    @pick_and_pack = OrderBatch.new
    @q = OrderBatch.ransack(params[:q])
    @pick_and_packs = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@pick_and_packs) if params[:export_csv].present?
    @user_list = User.all
    respond_to do |format|
      format.html
      format.csv
      format.pdf do
        render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'pick_and_packs/index.pdf.erb'
      end
    end
  end

  # GET /services/1 or /services/1.json
  def show
    @orders = @pick_and_pack.channel_orders
    respond_to do |format|
      format.js
    end
  end

  def show_order
    @batch_order = ChannelOrder.find_by(id: params[:id])
    return if @batch_order.present?

    flash[:alert] = 'Orders not found'
    redirect_to pick_and_packs_path
  end

  # GET /services/new
  def new
    @packer = OrderBatch.new
  end

  def start_packing
    @batches = OrderBatch.joins(:channel_orders).uniq
    @q = OrderBatch.ransack(params[:q])
    @pick_and_packs = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    if params[:q].present?
      @orders = @pick_and_packs.last&.channel_orders
      if params[:order_id].present?
        @tracking_order = @orders.joins(:trackings).find_by('trackings.tracking_no': params[:order_id])
      end
    end
  end

  def courier_edit
    @mailRule = AssignRule.find_by(id: params[:assign_rule_id])
    if @mailRule.save_later
      @newRule = AssignRule.create(mail_service_rule_id: params[:mail_service_rule])
      if @newRule.present?
        ChannelOrder.find_by(id: params[:batch_order_id]).update(assign_rule_id: @newRule.id)
        flash[:notice] = 'Service Rule successfully updated.'
      else
        flash[:alert] = @batch.errors.full_messages
      end
    elsif @mailRule.update(mail_service_rule_id: params[:mail_service_rule])
      flash[:notice] = 'Service Rule successfully updated.'
    else
      flash[:alert] = @batch.errors.full_messages
    end
    redirect_to request.referrer
  end

  def address_edit
    @address = Address.where(id: params[:address][:address_id].split(' '), address_title: 'delivery')
    if @address.present?
      if @address.update(address: params[:address][:address], city: params[:address][:city],
                         region: params[:address][:region], postcode: params[:address][:postcode])
        flash[:notice] = 'Address successfully updated.'
      else
        flash[:alert] = @batch.errors.full_messages
      end
    else
      @newAddress = SystemUser.find_by(id: params[:address][:system_user_id]).addresses.build(
        address_title: 'delivery', address: params[:address][:address], city: params[:address][:city], region: params[:address][:region], postcode: params[:address][:postcode]
      )
      if @newAddress.save
        flash[:notice] = 'Address successfully updated.'
      else
        flash[:alert] = @batch.errors.full_messages
      end
    end
    redirect_to request.referrer
  end

  def assign_user
    @batch = OrderBatch.find(params[:batch_id])
    if @batch.update(user_id: params[:user_id])
      flash[:notice] = 'User assigned to batch successfully created.'
    else
      flash[:alert] = @batch.errors.full_messages
    end
    redirect_to pick_and_packs_path
  end

  # GET /services/1/edit
  def edit; end

  # POST /services or /services.json
  def create
    @packer = OrderBatch.new(packer_params)
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
    @pick_and_pack.destroy
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
      packer = OrderBatch.with_deleted.create_with(name: row['name'])
                         .find_or_create_by(name: row['name'])
      flash[:alert] = "#{packer.errors.full_messages} at ID: #{packer.id} , Try again " unless update_packer(packer,
                                                                                                             row)
    end
  end

  def update_pakcer(packer, row)
    packer.update(row.to_hash)
  end

  def bulk_method
    redirect_to pick_and_packs_path
  end

  def archive
    @q = OrderBatch.only_deleted.ransack(params[:q])
    @packers = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    object_ids = params[:object_ids]
    object_id = params[:object_id]
    commit = params[:commit]
    if object_id.present? && klass_single_restore(object_id)
      flash[:notice] = 'Batch restore successfully'
    else
      restore_or_delete(commit, object_ids, name)
    end
    redirect_to archive_pick_and_packs_path
  end

  def klass_single_restore(object_id)
    if object_id.present?
      OrderBatch.restore(object_id)
      true
    else
      false
    end
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && OrderBatch.only_deleted.find(params[:object_id]).really_destroy!
                       'Batch deleted successfully'
                     else
                       'Batch cannot be deleted/Please select something to delete'
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
