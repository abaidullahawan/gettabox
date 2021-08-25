class SystemUsersController < ApplicationController

  before_action :authenticate_user!
  before_action :find_system_user, only: [:show, :edit, :update, :destroy]

  def index
    @q = SystemUser.ransack(params[:q])
    @system_users = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def new
    @system_user = SystemUser.new
  end

  def create
    @system_user = SystemUser.new(system_user_params)
    if @system_user.save
      flash[:notice] = "System User created successfully."
      redirect_to system_users_path
    else
      flash.now[:notice] = "System User not created."
      render 'new'
    end
  end

  def show
  end

  def edit
  end

  def update
    if @system_user.update(system_user_params)
      flash[:notice] = "System User updated successfully."
      redirect_to system_users_path
    else
      flash.now[:notice] = "System User not updated."
      render 'edit'
    end
  end

  def destroy
    if @system_user.destroy
      flash[:notice] = "System User destroyed successfully."
      redirect_to system_users_path
    else
      flash.now[:notice] = "System User not destroyed."
      render system_users_path
    end
  end

  private
    def find_system_user
      @system_user = SystemUser.find(params[:id])
    end

    def system_user_params
      params.require(:system_user).permit(:sku, :user_type)
    end

end
