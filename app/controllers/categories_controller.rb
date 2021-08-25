class CategoriesController < ApplicationController

  before_action :authenticate_user!
  before_action :find_category, only: [:show, :edit, :update, :destroy]

  def index
    @q = Category.ransack(params[:q])
    @categories = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:notice] = "Category created successfully."
      redirect_to categories_path
    else
      flash.now[:notice] = "Category not created."
      render 'new'
    end
  end

  def show
  end

  def edit
  end

  def update
    if @category.update(category_params)
      flash[:notice] = "Category updated successfully."
      redirect_to categories_path
    else
      flash.now[:notice] = "Category not updated."
      render 'edit'
    end
  end

  def destroy
    if @category.destroy
      flash[:notice] = "Category destroyed successfully."
      redirect_to categories_path
    else
      flash.now[:notice] = "Category not destroyed."
      render categories_path
    end
  end

  private
    def find_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:title)
    end

end
