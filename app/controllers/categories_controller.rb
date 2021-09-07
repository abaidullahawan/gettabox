class CategoriesController < ApplicationController

  before_action :authenticate_user!
  before_action :find_category, only: [:show, :edit, :update, :destroy]

  def index
    @q = Category.ransack(params[:q])
    @categories = @q.result(distinct: true).page(params[:page]).per(params[:limit])
    export_csv(@categories) if params[:export_csv].present?
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

  def export_csv(categories)
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data categories.to_csv, filename: "categories-#{Date.today}.csv" }
    end
  end

  def bulk_method
    params[:object_ids].delete('0')
    if params[:object_ids].present?
      params[:object_ids].each do |p|
        category = Category.find(p.to_i)
        category.delete
      end
      flash[:notice] = 'Categories archive successfully'
      redirect_to categories_path
    else
      flash[:alert] = 'Please select something to perform action.'
      redirect_to categories_path
    end
  end

  def archive
    @q = Category.only_deleted.ransack(params[:q])
    @categories = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    if params[:object_id].present? && Category.restore(params[:object_id])
      flash[:notice] = 'Category restore successful'
      redirect_to archive_categories_path
    elsif params[:object_ids].present?
      params[:object_ids].delete('0')
      params[:object_ids].each do |p|
        Category.restore(p.to_i)
      end
      flash[:notice] = 'Categories restore successful'
      redirect_to archive_categories_path
    else
      flash[:notice] = 'Category cannot be restore'
      redirect_to archive_categories_path
    end
  end

  private
    def find_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:title, :description)
    end

end
