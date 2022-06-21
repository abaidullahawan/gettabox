# frozen_string_literal: true

# Company Setting
class GeneralSettingsController < ApplicationController
  before_action :set_general_setting, only: %i[show edit update destroy]

  # GET /general_settings or /general_settings.json
  def index
    @q = GeneralSetting.ransack(params[:q])
    @general_settings = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@general_settings) if params[:export_csv].present?
    @general_setting = GeneralSetting.new
    @general_setting.addresses.build(address_title: 'admin')
    @general_setting.addresses.build(address_title: 'delivery')
    @general_setting.addresses.build(address_title: 'billing')
  end

  # GET /general_settings/1 or /general_settings/1.json
  def show; end

  # GET /general_settings/new
  def new
    @general_setting = GeneralSetting.new
    @setting_address = @general_setting.build_address
  end

  # GET /general_settings/1/edit
  def edit; end

  # POST /general_settings or /general_settings.json
  def create
    @general_setting = GeneralSetting.new(general_setting_params)

      if @general_setting.save
        flash[:notice] = 'General setting was successfully created.'
      else
        flash[:alert] = @general_setting.errors
      end
      redirect_to general_settings_path
  end

  # PATCH/PUT /general_settings/1 or /general_settings/1.json
  def update
    if @general_setting.update(general_setting_params)
      flash[:notice] = 'General setting was successfully updated.'
      redirect_to general_setting_path(@general_setting)
    else
      flash.now[:alert] = @general_setting.errors.full_messages
      render :show
    end
  end

  # DELETE /general_settings/1 or /general_settings/1.json
  def destroy
    @general_setting.destroy
    respond_to do |format|
      format.html { redirect_to general_settings_url, notice: 'General setting was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_general_setting
    @general_setting = GeneralSetting.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def general_setting_params
    params.require(:general_setting)
          .permit(:name, :display_name, :phone, :vat_reg_no, :company_reg_no,
            addresses_attributes: %i[ id address_title company address city region postcode country _destroy ]
          )
  end
end
