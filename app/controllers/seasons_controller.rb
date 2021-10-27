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

  def index
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
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data seasons.to_csv, filename: "seasons-#{Date.today}.csv" }
    end
  end

  def import
    if params[:file].present? && params[:file].path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(params[:file])
      csv = CSV.parse(csv_text, headers: true)
      if csv.headers == Season.column_names
        csv.each do |row|
          data = Season.find_or_initialize_by(id: row['id'])
          unless data.update(row.to_hash)
            flash[:alert] = "#{data.errors.first.full_message} at ID: #{data.id} , Try again"
            redirect_to seasons_path
          end
        end
        flash[:alert] = 'File Upload Successful!'
      else
        flash[:alert] = 'File not matched! Please change file'
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
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
    @searched_season_by_name = Season.where('lower(name) LIKE ?',
                                            "#{params[:search_value].downcase}%").pluck(:name).uniq
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
end
