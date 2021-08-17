class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :user_sub_role
  before_action :find_user, only: [:edit, :update, :show, :destroy]
  # before_filter :default_created_by, only: :create

  def index
    @users = User.where(role: @user_sub_role)
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
      redirect_to users_path
    else
      render 'new'
    end
  end

  def edit
    @personal_detail = @user. personal_detail
    @contact_details = @personal_detail.contact_details
    @work_details = @personal_detail.work_details
    @study_details = @personal_detail.study_details
  end

  def update
    if @user.update(user_params)
      redirect_to users_path
    else
      render 'edit'
    end
  end

  def show
  end

  def destroy
    @user.destroy

    redirect_to users_path
  end

  def profile

  end
  private

  def user_sub_role
    if current_user.role_super_admin?
      @user_sub_role = 'admin'
    elsif current_user.role_admin?
      @user_sub_role = 'staff'
    else
      @user_sub_role = nil
    end
  end

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.
    require(:user).
    permit( :email,
            :password,
            :password_confirmation,
            :role,
            :created_by,
            :avatar,
            personal_detail_attributes:
            [ :id,
              :first_name,
              :last_name,
              :dob,
              :gender,
              contact_details_attributes:
              [ :phone_number,
                :email,
                :street_address,
                :city,
                :province,
                :country,
                :zip,
                :_destroy

              ],
              work_details_attributes:
              [ :company_name,
                :position,
                :city,
                :description,
                :currently_working,
                :from,
                :to,
                :_destroy
              ],
              study_details_attributes:
              [ :school,
                :degree,
                :format,
                :description,
                :from,
                :to,
                :_destroy
              ]
            ]
    )
  end

end