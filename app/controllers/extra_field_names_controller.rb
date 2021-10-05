class ExtraFieldNamesController < ApplicationController
  def index
    @extra_field_names = ExtraFieldName.all
    @table_names = ["Product", "SystemUser"]
    @extra_field_name = ExtraFieldName.new
  end

  def create
    @extra_field_name = ExtraFieldName.new(extra_field_name_params)
    respond_to do |format|
    if @extra_field_name.save
      format.html { redirect_to extra_field_names_path, notice: "Extra Field successfully created." }
      format.json { render :index, status: :created }
    else
      format.html { render :index, status: :unprocessable_entity }
      format.json { render json: @extra_field_name.errors, status: :unprocessable_entity }
    end
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