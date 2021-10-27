# frozen_string_literal: true

# Users
class UsersController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :user_sub_role
  before_action :find_user, only: %i[edit show destroy]
  before_action :load_resources, only: %i[show edit]
  before_action :update_without_password, only: %i[update]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]
  # before_filter :default_created_by, only: :create

  def index
    @q = User.where(role: @user_sub_role).ransack(params[:q])
    @users = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@users) if params[:export_csv].present?
  end

  def new
    @user = User.new
    @personal_detail = @user.build_personal_detail
    @personal_detail.contact_details.build
    @personal_detail.work_details.build
    @personal_detail.study_details.build
  end

  def create
    @user = User.new(user_params)
    @user.update(created_by: current_user.id)
    if @user.save
      flash[:notice] = 'User cerated successfully.'
      redirect_to user_path(@user)
    else
      flash.now[:alert] = 'User cannot be create.'
      render 'new'
    end
  end

  def edit; end

  def load_resources
    @personal_detail = @user.personal_detail
    @personal_detail = @user.build_personal_detail if @personal_detail.blank?
    @contact_details = @personal_detail.contact_details
    @personal_detail.contact_details.build if @contact_details.blank?
    @work_details = @personal_detail.work_details
    @personal_detail.work_details.build if @work_details.blank?
    @study_details = @personal_detail.study_details
    @personal_detail.study_details.build if @study_details.blank?
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:notice] = 'User updated successfully.'
      redirect_to user_path(@user)
    else
      render 'show'
    end
  end

  def show; end

  def destroy
    @user.destroy

    redirect_to users_path
  end

  def import
    if params[:file].present? && params[:file].path.split('.').last.to_s.downcase == 'csv'
      csv_text = File.read(params[:file])
      csv = CSV.parse(csv_text, headers: true)
      if csv.headers == User.column_names
        csv.delete('id')
        csv.delete('encrypted_password')
        csv.delete('created_at')
        csv.delete('updated_at')

        csv.each do |row|
          user = User.find_or_initialize_by(email: row['email'])
          unless if user.new_record?
                   user.update(password: 'Sample',
                               password_confirmation: 'Sample')
                 else
                   user.update(row.to_hash)
                 end
            flash[:alert] = "#{user.errors.full_messages} , Please try again . . . "
            redirect_to users_path
          end
        end
        flash[:alert] = 'File Upload Successful!'
      else
        flash[:alert] = 'File not matched! Please change file'
      end
    else
      flash[:alert] = 'File format no matched! Please change file'
    end
    redirect_to users_path
  end

  def bulk_method
    redirect_to users_path
  end

  def archive
    @q = User.only_deleted.ransack(params[:q])
    @users = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_users_path
  end

  def profile; end

  def export_csv(users)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data users.to_csv, filename: "users-#{Date.today}.csv" }
    end
  end

  private

  def user_sub_role
    @user_sub_role = if current_user.role_super_admin?
                       'admin'
                     elsif current_user.role_admin?
                       'staff'
                     end
  end

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user)
          .permit(:email, :password, :password_confirmation, :role, :created_by, :profile_image,
                  personal_detail_attributes:
                  [:id, :first_name, :last_name, :dob, :gender,
                   { contact_details_attributes:
                   %i[id phone_number email street_address city province country zip _destroy],
                     work_details_attributes:
                   %i[id company_name position city description currently_working from to _destroy],
                     study_details_attributes:
                   %i[id school degree format description from to _destroy] }])
  end

  def update_without_password
    return unless params[:user][:password].blank? || params[:user][:password_confirmation].blank?

    params[:user].delete(:password)
    params[:user].delete(:password_confirmation)
  end
end
