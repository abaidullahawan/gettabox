class SystemUsersController < ApplicationController

  before_action :authenticate_user!
  before_action :find_system_user, only: [:show, :edit, :update, :destroy]

  def index
    @q = SystemUser.where(user_type: 'supplier').ransack(params[:q])
    @system_users = @q.result(distinct: true).page(params[:page]).per(params[:limit])
    export_csv(@system_users) if params[:export_csv].present?

    @system_user = SystemUser.new
  end

  def new
    @system_user = SystemUser.new
  end

  def create
    @system_user = SystemUser.new(system_user_params)
    if @system_user.save
      @system_user.update(user_type: 'supplier')
      flash[:notice] = "Supplier created successfully."
      redirect_to system_users_path
    else
      flash.now[:notice] = "Supplier not created."
      render 'new'
    end
  end

  def show
  end

  def edit
  end

  def update
    if @system_user.update(system_user_params)
      @system_user.update(user_type: 'supplier')
      flash[:notice] = "Supplier updated successfully."
      redirect_to system_users_path
    else
      flash.now[:notice] = "Supplier not updated."
      render 'edit'
    end
  end

  def destroy
    if @system_user.destroy
      flash[:notice] = "Supplier destroyed successfully."
      redirect_to system_users_path
    else
      flash.now[:notice] = "Supplier not destroyed."
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
    if params[:file].present? && params[:file].path.split(".").last.to_s.downcase == 'csv'
      csv_text = File.read(params[:file])
      csv = CSV.parse(csv_text, :headers => true)
      if csv.headers == SystemUser.column_names.excluding('id','user_type')
        csv.delete('id')
        csv.each do |row|
          data = SystemUser.find_or_initialize_by(sku: row['sku'])
          data.update(row.to_hash)
          data.update(user_type: 'supplier')
        end
        flash[:alert] = 'File Upload Successful!'
        redirect_to system_users_path
      else
        flash[:alert] = 'File not matched! Please change file'
        redirect_to system_users_path
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
      redirect_to system_users_path
    end
  end

  private
    def find_system_user
      @system_user = SystemUser.find(params[:id])
    end

    def system_user_params
      params.require(:system_user).permit(:sku, :user_type, :name, :payment_method, :days_for_payment, :days_for_order_to_completion, :days_for_completion_to_delivery, :currency_symbol, :exchange_rate)
    end

end
