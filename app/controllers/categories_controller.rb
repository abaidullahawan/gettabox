# frozen_string_literal: true

# Categories
class CategoriesController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :find_category, only: %i[show edit update destroy]
  before_action :filter_object_ids, only: %i[bulk_method restore]
  before_action :klass_bulk_method, only: %i[bulk_method]
  before_action :klass_restore, only: %i[restore]

  def index
    @category_exports = ExportMapping.where(table_name: 'Category')
    @q = Category.ransack(params[:q])
    @categories = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(params[:limit])
    export_csv(@categories) if params[:export_csv].present?

    generate_pdf if params[:format].eql? 'pdf'
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:notice] = 'Category created successfully.'
      redirect_to categories_path
    else
      flash.now[:notice] = 'Category not created.'
      render 'new'
    end
  end

  def show; end

  def edit; end

  def update
    if @category.update(category_params)
      flash[:notice] = 'Category updated successfully.'
      redirect_to categories_path
    else
      flash.now[:notice] = 'Category not updated.'
      render 'edit'
    end
  end

  def destroy
    if @category.destroy
      flash[:notice] = 'Category archive successfully.'
      redirect_to categories_path
    else
      flash.now[:notice] = 'Category not archived.'
      render categories_path
    end
  end

  def export_csv(categories)
    categories = categories.where(selected: true) if params[:selected]
    if params[:export_mapping].present?
      @export_mapping = ExportMapping.find(params[:export_mapping])
      attributes = @export_mapping.export_data
      @csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        categories.each do |category|
          csv << attributes.map { |attr| category.send(attr) }
        end
      end
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data @csv, filename: "categories-#{Date.today}.csv" }
      end
    else
      request.format = 'csv'
      respond_to do |format|
        format.csv { send_data categories.to_csv, filename: "categories-#{Date.today}.csv" }
      end
    end
  end

  def generate_pdf
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: 'file.pdf', viewport_size: '1280x1024', template: 'categories/index.pdf.erb'
      end
    end
  end

  def bulk_method
    redirect_to categories_path
  end

  def archive
    @q = Category.only_deleted.ransack(params[:q])
    @categories = @q.result(distinct: true).page(params[:page]).per(params[:limit])
  end

  def restore
    redirect_to archive_categories_path
  end

  def permanent_delete
    flash[:notice] = if params[:object_id].present? && Category.only_deleted.find(params[:object_id]).really_destroy!
                       'Category deleted successfully'
                     else
                       'Category cannot be deleted/Please select something to delete'
                     end
    redirect_to archive_categories_path
  end

  def search_category_by_title
    @searched_category_by_title = Category.ransack('title_cont': params[:search_value].downcase.to_s)
                                          .result.limit(20).pluck(:id, :title)
    respond_to do |format|
      format.json { render json: @searched_category_by_title }
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
