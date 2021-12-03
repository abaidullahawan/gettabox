# frozen_string_literal: true

# service rules for order items
class MailServiceRulesController < ApplicationController
  include ImportExport

  before_action :set_mail_service_rule, only: %i[show edit update destroy]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]

  # GET /mail_service_rules or /mail_service_rules.json
  def index
    @q = MailServiceRule.ransack(params[:q])
    @mail_service_rules = @q.result.page(params[:page]).per(params[:limit])
    @mail_service_rule = MailServiceRule.new
  end

  # GET /mail_service_rules/1 or /mail_service_rules/1.json
  def show; end

  # GET /mail_service_rules/new
  def new
    @mail_service_rule = MailServiceRule.new
  end

  # GET /mail_service_rules/1/edit
  def edit; end

  # POST /mail_service_rules or /mail_service_rules.json
  def create
    @mail_service_rule = MailServiceRule.new(mail_service_rule_params)
    if @mail_service_rule.save
      redirect_to mail_service_rules_path
      flash[:notice] = "Mail service rule was successfully created."
    else
      flash[:alert] = "#{@mail_service_rule.errors.full_messages} Cannot create rule"
      redirect_to mail_service_rules_path
    end
  end

  # PATCH/PUT /mail_service_rules/1 or /mail_service_rules/1.json
  def update
    respond_to do |format|
      if @mail_service_rule.update(mail_service_rule_params)
        format.html { redirect_to @mail_service_rule, notice: 'Mail service rule was successfully updated.' }
        format.json { render :show, status: :ok, location: @mail_service_rule }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @mail_service_rule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mail_service_rules/1 or /mail_service_rules/1.json
  def destroy
    @mail_service_rule.destroy
    respond_to do |format|
      format.html { redirect_to mail_service_rules_url, notice: 'Mail service rule was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def new_rule
    @new_rule = MailServiceRule.new
  end

  def bulk_method
    redirect_to mail_service_rules_path
  end

  def archive
    @q = MailServiceRule.only_deleted.ransack(params[:q])
    @mail_service_rules = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_mail_service_rules_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && MailServiceRule.only_deleted.find(params[:object_id]).really_destroy!
                       'Mail Service Rule deleted successfully'
                     else
                       'Mail Service Rule cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_mail_service_rules_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_mail_service_rule
    @mail_service_rule = MailServiceRule.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def mail_service_rule_params
    params.require(:mail_service_rule).permit(
      :service_name, :rule_name, :channel_order_id, :public_cost, :initial_weight, :additonal_cost_per_kg,
      :vat_percentage, :label_type, :csv_file, :courier_account, :rule_naming_type, :manual_dispatch_label_template,
      :priority_delivery_days, :is_priority, :estimated_delivery_days, :courier_id, :service_id, :print_queue_type,
      :additional_label, :pickup_address, :bonus_score, :base_weight, :base_weight_max,
      mail_service_labels_attributes: %i[id length width height weight product_ids courier_id _destroy],
      rules_attributes: %i[id rule_field rule_operator rule_value is_optional mail_service_rule_id _destroy]
    )
  end
end
