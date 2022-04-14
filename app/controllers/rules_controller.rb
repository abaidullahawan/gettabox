# frozen_string_literal: true

# rules are for products
class RulesController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :set_season, only: %i[show update destroy]
  before_action :new, only: %i[index]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    # @season_exports = ExportMapping.where(table_name: 'Rule')
    @q = AssignRule.where(save_later: true).ransack(params[:q])
    @rules = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    # export_csv(@rules) if params[:export_csv].present?
    @rule = AssignRule.new
  end

  def show
    @mail_service_rules = MailServiceRule.all
    @selected_products = ChannelProduct.where(item_sku: @rule.criteria.map(&:first))
    @quantities = @rule.criteria.map(&:last)
  end

  def new; end

  def edit; end

  def create
    @rule = AssignRule.new(season_params)
    if @rule.save
      flash[:notice] = 'Rule created successfully.'
      redirect_to season_path(@rule)
    else
      flash.now[:notice] = 'Rule not created.'
      render 'index'
    end
  end

  def update
    if @rule.update(season_params)
      flash[:notice] = 'Rule updated successfully.'
      redirect_to season_path(@rule)
    else
      flash.now[:notice] = 'Rule not created.'
      render 'show'
    end
  end

  def destroy
    return unless @rule.destroy && @rule.channel_orders.update_all(assign_rule_id: nil)

    flash[:notice] = 'Rule archived successfully.'
    redirect_to rules_path
  end

  def export_csv(rules)
    rules = rules.where(selected: true) if params[:selected]
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        rules.each do |rule|
          csv << attributes.map { |attr| rule.send(attr) }
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "rules-#{Date.today}.csv"}
      end
    else
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data rules.to_csv, filename: "rules-#{Date.today}.csv" }
      end
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
    redirect_to rules_path
  end

  def bulk_method
    redirect_to rules_path
  end

  # def archive
  #   @q = AssignRule.only_deleted.ransack(params[:q])
  #   @rules = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  # end

  # def restore
  #   redirect_to archive_rules_path
  # end

  # def permanent_delete
  #   flash[:notice] = if params[:object_id].present? && AssignRule.only_deleted.find(params[:object_id]).really_destroy!
  #                      'Rule deleted successfully'
  #                    else
  #                      'Rule cannot be deleted/Please select something to delete'
  #                    end
  #   redirect_to archive_rules_path
  # end

  def search_season_by_name
    @searched_season_by_name = AssignRule.ransack('name_cont': params[:search_value].downcase.to_s)
                                     .result.limit(20).pluck(:id, :name)
    respond_to do |format|
      format.json { render json: @searched_season_by_name }
    end
  end

  private

  def set_season
    @rule = AssignRule.find(params[:id])
  end

  def season_params
    params.require(:rule).permit(:name, :description)
  end

  def csv_create_records(csv)
    csv.each do |row|
      data = AssignRule.with_deleted.find_or_initialize_by(name: row['name'])
      flash[:alert] = "#{data.errors.full_messages} at ID: #{data.id} , Try again" unless data.update(row.to_hash)
    end
  end
end
