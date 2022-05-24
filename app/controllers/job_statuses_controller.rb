# frozen_string_literal: true

# Courier has Service which used for mailing
class JobStatusesController < ApplicationController
  include ImportExport

  before_action :set_job_status, only: %i[show edit update destroy]


  # GET /couriers or /couriers.json
  def index
    JobStatus.where('Date(created_at) < ?', Date.today - 2.days).destroy_all
    @q = JobStatus.ransack(params[:q])
    @job_statuses = @q.result
    load_statuses
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
  def update
    @job = JobStatus.find(params[:id])
    @job.update(status: job_status(params[:commit]))
    redirect_to request.referrer
  end

  def destroy
    if @set_job_status.destroy
      flash[:notice] = 'The Inqueued Job has been cancelled.'
      redirect_to request.referrer
    else
      flash.now[:alert] = @set_job_status.errors.full_messages
      render request.referrer
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_job_status
    @set_job_status = JobStatus.find(params[:id])
  end

  private

  def load_statuses
    @inqueue_job = @job_statuses.where(status: 'inqueue').order(created_at: :desc).page(params[:page]).per(params[:limit])
    @retry_job = @job_statuses.where(status: 'retry').order(created_at: :desc).page(params[:page]).per(params[:limit])
    @busy_job = @job_statuses.where(status: 'busy').order(created_at: :desc).page(params[:page]).per(params[:limit])
    @processed_job = @job_statuses.where(status: 'processed').order(created_at: :desc).page(params[:page]).per(params[:limit])
    @cancelled_job = @job_statuses.where(status: 'cancelled').order(created_at: :desc).page(params[:page]).per(params[:limit])
  end

  def job_status(status)
    statuses = {
      'Cancel' => 'cancelled'
    }
    statuses[status]
  end
end
