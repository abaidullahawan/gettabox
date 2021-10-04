class SystemUsersController < ApplicationController

  before_action :authenticate_user!
  before_action :find_system_user, only: [:show, :edit, :update, :destroy]
  before_action :get_field_names, only: [ :new, :create, :show, :index, :update ]
  before_action :new, only: [ :index ]
  skip_before_action :verify_authenticity_token, :only => [:create, :update]
  def index
    @q = SystemUser.where(user_type: 'supplier').ransack(params[:q])
    @system_users = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    @purchase_orders = PurchaseOrder.all
    if params[:export_csv].present?
      export_csv(@system_users)
    else
      respond_to do |format|
        format.html
        format.pdf do
          render  :pdf => "file.pdf", 
                  :viewport_size => '1280x1024',
                  :template => 'system_users/index.pdf.erb'
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
    @system_user = SystemUser.new(system_user_params)
    @system_user.build_extra_field_value
    @system_user.extra_field_value.field_value = {} if @system_user.extra_field_value.field_value.nil?
    @field_names.each do |field_name|
      @system_user.extra_field_value.field_value["#{field_name}"] = params[:"#{field_name}"]
    end
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
    @system_user.extra_field_value.field_value = {} if @system_user.extra_field_value.field_value.nil?
    @field_names.each do |field_name|
      @system_user.extra_field_value.field_value["#{field_name}"] = params[:"#{field_name}"]
    end
    if @system_user.update(system_user_params)
      @system_user.update(user_type: 'supplier')
      flash[:notice] = "Supplier updated successfully."
      redirect_to system_user_path(@system_user)
    else
      flash.now[:notice] = "Supplier not updated."
      render 'show'
    end
  end

  def destroy
    if @system_user.destroy
      flash[:notice] = "Supplier archive successfully."
      redirect_to system_users_path
    else
      flash.now[:notice] = "Supplier not archived."
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
      if csv.headers == SystemUser.column_names.excluding('user_type')
        csv.each do |row|
          data = SystemUser.find_or_initialize_by(id: row['id'])
          if !(data.update(row.to_hash))
            flash[:alert] = "#{data.errors.first.full_message} at ID: #{data.id} , Try again"
            redirect_to system_users_path and return
          else
            data.update(user_type: 'supplier')
          end
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

  def bulk_method
    params[:object_ids].delete('0')
    if params[:object_ids].present?
      params[:object_ids].each do |p|
        product = SystemUser.find(p.to_i)
        product.delete
      end
      flash[:notice] = 'Suppliers archive successfully'
      redirect_to system_users_path
    else
      flash[:alert] = 'Please select something to perform action.'
      redirect_to system_users_path
    end
  end

  def archive
    @q = SystemUser.only_deleted.ransack(params[:q])
    @system_users = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    if params[:object_id].present? && SystemUser.restore(params[:object_id])
      flash[:notice] = 'Supplier restore successful'
      redirect_to archive_system_users_path
    elsif params[:object_ids].present?
      params[:object_ids].delete('0')
      params[:object_ids].each do |p|
        SystemUser.restore(p.to_i)
      end
      flash[:notice] = 'Suppliers restore successful'
      redirect_to archive_system_users_path
    else
      flash[:notice] = 'Supplier cannot be restore'
      redirect_to archive_system_users_path
    end
  end

  def search_system_user_by_name
    @searched_supplier_by_name = SystemUser.where("lower(name) LIKE ?", "%#{ params[:supplier_name].downcase }%").uniq
    respond_to do |format|
      format.json  { render json: @searched_supplier_by_name }
    end
  end

  private
    def find_system_user
      @system_user = SystemUser.find(params[:id])
    end

    def get_field_names
      @field_names = []
      @field_names= ExtraFieldName.where(table_name: "SystemUser").pluck(:field_name)
    end

    def system_user_params
      params.require(:system_user).permit(:user_type, :name, :photo, :payment_method, :days_for_payment, :days_for_order_to_completion, :days_for_completion_to_delivery, :currency_symbol, :exchange_rate, :email, :phone_number,
        address_attributes:[ 
        :id,
        :company,
        :address,
        :city,
        :region,
        :postcode,
        :country
        ],
        extra_field_value_attributes:
        [
          :id,
          :field_value
        ]
      )
    end

end
