# frozen_string_literal: true

# customer for orders
class CustomersController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  # before_action :find_category, only: %i[show edit update destroy]
  # before_action :filter_object_ids, only: %i[bulk_method restore]
  # before_action :klass_bulk_method, only: %i[bulk_method]
  # before_action :klass_restore, only: %i[restore]

  def index
    @q = SystemUser.where(user_type: 0).ransack(params[:q])
    @customers = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@customers) if params[:export_csv].present?
    @customer = SystemUser.new
    @customer.build_address
  end

  def show; end

  def new
    @customer = SystemUser.new
  end

  def edit; end

  def create
    @customer = SystemUser.new(customer_params)
    if @customer.save
      flash[:notice] = 'SystemUser was successfully created.'
    else
      flash[:alert] = @customer.errors.full_messages
    end
    redirect_to customers_path
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: 'Customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_url, notice: 'Customer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def export_csv(customers)
    customers = Customers.where(selected: true) if params[:selected]
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data customers.to_csv, filename: "customers-#{Date.today}.csv" }
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
    redirect_to customers_path
  end

  def bulk_method
    redirect_to customers_path
  end

  def archive
    @q = SystemUser.only_deleted.ransack(params[:q])
    @customers = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_customers_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && SystemUser.only_deleted.find(params[:object_id]).really_destroy!
                       'customer deleted successfully'
                     else
                       'customer cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_customers_path
  end

  private

  def set_customer
    @customer = SystemUser.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name)
  end
end