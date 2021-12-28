# frozen_string_literal: true

# seasons are for products
class SeasonsController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :set_season, only: %i[show update destroy]
  before_action :new, only: %i[index]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    @season_exports = ExportMapping.where(table_name: 'Season')
    @q = Season.ransack(params[:q])
    @seasons = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@seasons) if params[:export_csv].present?
    @season = Season.new
  end

  def show; end

  def new; end

  def edit; end

  def create
    @season = Season.new(season_params)
    if @season.save
      flash[:notice] = 'Season created successfully.'
      redirect_to season_path(@season)
    else
      flash.now[:notice] = 'Season not created.'
      render 'index'
    end
  end

  def update
    if @season.update(season_params)
      flash[:notice] = 'Season updated successfully.'
      redirect_to season_path(@season)
    else
      flash.now[:notice] = 'Season not created.'
      render 'show'
    end
  end

  def destroy
    return unless @season.destroy

    flash[:notice] = 'Season archived successfully.'
    redirect_to seasons_path
  end

  def export_csv(seasons)
    seasons = seasons.where(selected: true) if params[:selected]
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        seasons.each do |season|
          csv << attributes.map { |attr| season.send(attr) }
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "seasons-#{Date.today}.csv"}
      end
    else
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data seasons.to_csv, filename: "seasons-#{Date.today}.csv" }
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
    redirect_to seasons_path
  end

  def bulk_method
    redirect_to seasons_path
  end

  def archive
    @q = Season.only_deleted.ransack(params[:q])
    @seasons = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_seasons_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && Season.only_deleted.find(params[:object_id]).really_destroy!
                       'Season deleted successfully'
                     else
                       'Season cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_seasons_path
  end

  def search_season_by_name
    @searched_season_by_name = Season.ransack('name_cont': params[:search_value].downcase.to_s)
                                     .result.limit(20).pluck(:id, :name)
    respond_to do |format|
      format.json { render json: @searched_season_by_name }
    end
  end

  private

  def set_season
    @season = Season.find(params[:id])
  end

  def season_params
    params.require(:season).permit(:name, :description)
  end

  def csv_create_records(csv)
    csv.each do |row|
      data = Season.with_deleted.find_or_initialize_by(name: row['name'])
      flash[:alert] = "#{data.errors.full_messages} at ID: #{data.id} , Try again" unless data.update(row.to_hash)
    end
  end
end
