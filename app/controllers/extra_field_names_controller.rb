class ExtraFieldNamesController < ApplicationController
  def index
    @extra_field_names = ExtraFieldName.all
    @table_names = ["Product", "SystemUser"]
    @extra_field_name = ExtraFieldName.new
  end

  def create
    @extra_field_name = ExtraFieldName.new(extra_field_name_params)
    if @extra_field_name.save
      flash[:notice] = "Extra Field successfully created."
      redirect_to extra_field_names_path
    else
      flash[:notice] = "Extra Field cannot be created."
      redirect_to extra_field_names_path
    end
  end

  def destroy
    @extra_field_name = ExtraFieldName.find(params[:id])
    @extra_field_name.destroy
    if @extra_field_name.destroy
      flash[:notice] = "Field Name Deleted Successfully."
      redirect_to extra_field_names_path
    else
      flash.now[:notice] = "Field Name not Deleted."
      render extra_field_names_path
    end
  end

  private

  def extra_field_name_params
    params.require(:extra_field_name).permit(:field_name, :table_name)
  end
end