class CategoriesController < ApplicationController

  before_action :authenticate_user!
  before_action :find_category, only: [:show, :edit, :update, :destroy]

  def index
    @q = Category.ransack(params[:q])
    @categories = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    if params[:export_csv].present?
    export_csv(@categories) if params[:export_csv].present?
    else
    respond_to do |format|
      format.html
      format.pdf do
        render  :pdf => "file.pdf",
                :viewport_size => '1280x1024',
                :template => 'categories/index.pdf.erb'
      end
    end
    end
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
    params[:object_ids].delete('0') if params[:object_ids].present?
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
    params[:object_ids].delete('0') if params[:object_ids].present?
    if params[:object_id].present? && Category.restore(params[:object_id])
      flash[:notice] = 'Categories restore successfully'
    elsif params[:commit] == 'Delete' && params[:object_ids].present?
      params[:object_ids].each do |id|
        Category.only_deleted.find(id).really_destroy!
      end
      flash[:notice] = 'Categories deleted successfully'
    elsif params[:commit] == 'Restore' && params[:object_ids].present?
      params[:object_ids].each do |p|
        Category.restore(p.to_i)
      end
      flash[:notice] = 'Categories restored successfully'
    else
      flash[:notice] = 'Please select something to perform action'
    end
    redirect_to archive_categories_path
  end

  def permanent_delete
    if params[:object_id].present? && Category.only_deleted.find(params[:object_id]).really_destroy!
      flash[:notice] = 'Category deleted successfully'
      redirect_to archive_categories_path
    else
      flash[:notice] = 'Category cannot be deleted/Please select something to delete'
      redirect_to archive_categories_path
    end
  end

  def search_category_by_title
    @searched_category_by_title = Category.where("lower(title) LIKE ?", "#{ params[:search_value].downcase }%").pluck(:title).uniq
    respond_to do |format|
      format.json  { render json: @searched_category_by_title }
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
