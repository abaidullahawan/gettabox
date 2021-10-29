# frozen_string_literal: true

# System User are currently suppliers
class SystemUsersController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :find_system_user, only: %i[show edit update destroy]
  before_action :fetch_field_names, only: %i[new create show index update]
  before_action :new, :ransack_system_users, :purchase_orders, only: [:index]
  before_action :build_system_user, :build_extra_field_value, only: %i[create]
  before_action :build_extra_field_value, only: %i[update]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  skip_before_action :verify_authenticity_token, only: %i[create update]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    if params[:export_csv].present?
      export_csv(@system_users)
    else
      respond_to do |format|
        format.html
        format.pdf do
          render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'system_users/index.pdf.erb'
        end
      end
    end
  end

  def new
    @system_user = SystemUser.new
    @user_address = @system_user.build_address
    @system_user.build_extra_field_value
  end

  def create
    if @system_user.save
      @system_user.update(user_type: 'supplier')
      flash[:notice] = 'Supplier created successfully.'
      redirect_to system_users_path
    else
      flash.now[:notice] = 'Supplier not created.'
      render 'new'
    end
  end

  def show; end

  def edit; end

  def update
    if @system_user.update(system_user_params)
      @system_user.update(user_type: 'supplier')
      flash[:notice] = 'Supplier updated successfully.'
      redirect_to system_user_path(@system_user)
    else
      flash.now[:notice] = 'Supplier not updated.'
      render 'show'
    end
  end

  def destroy
    if @system_user.destroy
      flash[:notice] = 'Supplier archive successfully.'
      redirect_to system_users_path
    else
      flash.now[:notice] = 'Supplier not archived.'
      render system_users_path
    end
  end

  def export_csv(system_users)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data system_users.to_csv, filename: "suppliers-#{Date.today}.csv" }
    end
  end

  def import
    if @csv.present?
      csv_create_records(@csv)
      flash[:alert] = 'File Upload Successful!'
    end
    redirect_to system_users_path
  end

  def bulk_method
    redirect_to system_users_path
  end

  def archive
    @q = SystemUser.only_deleted.ransack(params[:q])
    @system_users = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_system_users_path
  end

  def search_system_user_by_name
    @searched_supplier_by_name = SystemUser.where('lower(name) LIKE ?',
                                                  "#{params[:search_value].downcase}%").pluck(:name).uniq
    respond_to do |format|
      format.json { render json: @searched_supplier_by_name }
    end
  end

  private

  def find_system_user
    @system_user = SystemUser.find(params[:id])
  end

  def fetch_field_names
    @field_names = []
    @field_names = ExtraFieldName.where(table_name: 'SystemUser').pluck(:field_name)
  end

  def system_user_params
    params.require(:system_user)
          .permit(:user_type, :name, :photo, :payment_method, :days_for_payment, :days_for_order_to_completion,
                  :days_for_completion_to_delivery, :currency_symbol, :exchange_rate, :email, :phone_number,
                  address_attributes: %i[id company address city region postcode country],
                  extra_field_value_attributes:
                  %i[id field_value])
  end

  def ransack_system_users
    @q = SystemUser.where(user_type: 'supplier').ransack(params[:q])
    @system_users = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
  end

  def purchase_orders
    @purchase_orders = PurchaseOrder.all
  end

  def build_system_user
    @system_user = SystemUser.new(system_user_params)
  end

  def build_extra_field_value
    @system_user.build_extra_field_value if @system_user.extra_field_value.nil?
    @system_user.extra_field_value.field_value = {} if @system_user.extra_field_value.field_value.nil?
    @field_names.each do |field_name|
      @system_user.extra_field_value.field_value[field_name.to_s] = params[:"#{field_name}"]
    end
  end

  def csv_create_records(csv)
    csv.each do |row|
      data = SystemUser.with_deleted.find_or_initialize_by(email: row['email'])
      if !data.update(row.to_hash)
        flash[:alert] = "#{data.errors.full_messages} at ID: #{data.id} , Try again"
        redirect_to system_users_path
      else
        data.update(user_type: 'supplier')
      end
    end
  end
end
