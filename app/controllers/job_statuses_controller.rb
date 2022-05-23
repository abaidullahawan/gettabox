# frozen_string_literal: true

# Courier has Service which used for mailing
class JobStatusesController < ApplicationController
  include ImportExport

  before_action :set_job_status, only: %i[show edit update destroy]


  # GET /couriers or /couriers.json
  def index
    JobStatus.where('Date(created_at) < ?', Date.today - 2.days).destroy_all
    @q = JobStatus.ransack(params[:q])
    @job_statuses = @q.result.order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@job_statuses) if params[:export_csv].present?
    @job_status = JobStatus.new
  end

  # GET /couriers/1 or /couriers/1.json
  def show; end

  # GET /couriers/new
  def new; end

  # GET /couriers/1/edit
  def edit; end

  # POST /couriers or /couriers.json
  def create; end

  # PATCH/PUT /couriers/1 or /couriers/1.json
  def update; end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_courier
    @set_job_status = JobStatus.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def courier_params
    params.require(:job_id).permit(:name, :status, :job_id)
  end
end
