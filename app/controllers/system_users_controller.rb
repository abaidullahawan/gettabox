# frozen_string_literal: true

# System User are currently suppliers
class SystemUsersController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :find_system_user, only: %i[show edit update destroy]
  before_action :fetch_field_names, only: %i[new create show index update]
  before_action :new, :ransack_system_users, :purchase_orders, only: [:index]
  before_action :build_system_user, only: %i[create]
  before_action :build_extra_field, only: %i[update create]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  skip_before_action :verify_authenticity_token, only: %i[create update]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  before_action :klass_import, only: %i[import]

  def index
    @system_user_exports = ExportMapping.where(table_name: 'SystemUser')
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
    @user_address = @system_user.addresses.build
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

  def version
    @versions = SystemUser.find_by(id: params[:id])&.versions
  end

  def export_csv(system_users)
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        system_users.each do |user|
          csv << attributes.map { |attr| user.send(attr) }
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "suppliers-#{Date.today}.csv" }
      end
    else
      system_users = system_users.where(selected: true) if params[:selected]
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data system_users.to_csv, filename: "suppliers-#{Date.today}.csv" }
      end
    end
  end

  def import
    if @csv.present?
      csv_create_records(@csv)
      flash[:notice] = 'File Upload Successful!'
    end
    redirect_to system_users_path
  end

  def import_supplier_products
    file = params[:file]
    if file.present? && file.path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(file).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
      csv = CSV.parse(csv_text, headers: true)
      csv.each do |row|
        hash = row.to_h.compact
        product = Product.find_by(sku: hash['VAR_SKU'])
        next unless product.present?

        hash.select {|k,_| k.include? 'Supplier_Name'}.each do |k, v|
          num = k.split('_').first
          supplier_record = hash.select {|k,_| k.include? num}
          supplier = SystemUser.find_or_initialize_by(user_type: 'supplier', name: v)
          next if product.product_suppliers.find_by(system_user_id: supplier.id).present?

          product.product_suppliers
                 .build(
                   system_user_id: supplier.id,
                   product_cost: supplier_record.select {|k,_| k.include? 'Price' }.first.last,
                   product_sku: supplier_record.select {|k,_| k.include? 'Sku' }&.first&.last,
                   product_vat: 5
                 ).save if supplier.save
        end
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    redirect_to system_users_path
  end

  def bulk_method
    redirect_to system_users_path
  end

  def archive
    @q = SystemUser.suppliers.only_deleted.ransack(params[:q])
    @system_users = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_system_users_path
  end

  def search_system_user_by_name
    @searched_supplier_by_name = SystemUser.suppliers.ransack('name_cont': params[:search_value].downcase.to_s)
                                           .result.limit(20).pluck(:id, :name)
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
    @field_names = ExtraFieldName.where(table_name: 'Supplier')
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
    @q = SystemUser.suppliers.ransack(params[:q])
    @system_users = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
  end

  def purchase_orders
    @purchase_orders = PurchaseOrder.all
  end

  def build_system_user
    @system_user = SystemUser.new(system_user_params)
  end

  def build_extra_field
    @system_user.build_extra_field_value if @system_user.extra_field_value.nil?
    @system_user.extra_field_value.field_value = {} if @system_user.extra_field_value.field_value.nil?
    @field_names.each do |field|
      @system_user.extra_field_value.field_value[field.field_name.to_s] = params[:"#{field.field_name}"]
    end
  end

  def csv_create_records(csv)
    csv.each do |row|
      data = SystemUser.with_deleted.find_or_initialize_by(email: row['email'])
      if !data.update(row.to_hash)
        flash[:alert] = "#{data.errors.full_messages} of ID: #{data.id} NAME: #{data.name} , Try again"
      else
        data.update(user_type: 'supplier')
      end
    end
  end

  def csv_headers_mapping
    supplier_name = { 'Barrettine' => '24542_Barrettine_Supplier_Name',
                      'Bartoline' => '24549_Bartoline_Supplier_Name',
                      'BestBargain' => '23338_BestBargain_Supplier_Name',
                      'Bio Bean Limited ' => '26674_Bio Bean Limited _Supplier_Name',
                      'Bird Brand ' => '25953_Bird Brand _Supplier_Name',
                      'branded matches ' => '32438_branded matches _Supplier_Name',
                      'Clearance King' => '23334_Clearance King_Supplier_Name',
                      'Costco' => '23333_Costco_Supplier_Name',
                      'costoc sale' => '23341_costoc sale_Supplier_Name',
                      'CPL' => '31639_CPL_Supplier_Name',
                      'Decco' => '23345_Decco_Supplier_Name',
                      'ESG' => '23336_ESG_Supplier_Name',
                      'Evergreen ' => '26985_Evergreen _Supplier_Name',
                      'Growth Technology Ltd' => '28050_Growth Technology Ltd_Supplier_Name',
                      'Home Pack LTD' => '29899_Home Pack LTD_Supplier_Name',
                      'HomeBase' => '29910_HomeBase_Supplier_Name',
                      'HS Fuels Ltd' => '31578_HS Fuels Ltd_Supplier_Name',
                      'Iceland' => '29436_Iceland_Supplier_Name',
                      'Logs Direct' => '32440_Logs Direct_Supplier_Name',
                      'Makeup' => '23346_Makeup_Supplier_Name',
                      'Makro' => '23342_Makro_Supplier_Name',
                      'Nice Pak' => '32411_Nice Pak_Supplier_Name',
                      'OTL' => '23347_OTL_Supplier_Name',
                      'Primark' => '23335_Primark_Supplier_Name',
                      'Rayburn ' => '26711_Rayburn _Supplier_Name',
                      'shonn brothers' => '23339_shonn brothers_Supplier_Name',
                      'Stax' => '23332_Stax_Supplier_Name',
                      'SWL' => '23337_SWL_Supplier_Name',
                      'The Vacuum Pouch Company' => '30261_The Vacuum Pouch Company_Supplier_Name',
                      'Tiger Tim ' => '24288_Tiger Tim _Supplier_Name',
                      'WE TEXTILES LTD' => '30328_WE TEXTILES LTD_Supplier_Name',
                      'Wham' => '23340_Wham_Supplier_Name',
                      'White Horse Energy' => '28869_White Horse Energy_Supplier_Name',
                      'y  y' => '23344_y  y_Supplier_Name',
                      'YY' => '23343_YY_Supplier_Name'
    }
  end
end
