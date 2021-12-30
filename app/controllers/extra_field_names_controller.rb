# frozen_string_literal: true

# Extra Fields for products
class ExtraFieldNamesController < ApplicationController
  def index
    @extra_field_names = ExtraFieldName.all
    @table_names = %w[Product Customer Supplier]
    @field_names = %w[Text Select]
    @extra_field_name = ExtraFieldName.new
    @extra_field_name.extra_field_options.build
  end

  def create
    @extra_field_name = ExtraFieldName.new(extra_field_name_params)
    flash[:notice] = if @extra_field_name.save
                       'Extra Field successfully created.'
                     else
                       'Extra Field cannot be created.'
                     end
    redirect_to extra_field_names_path
  end

  def destroy
    @extra_field_name = ExtraFieldName.find(params[:id])
    @extra_field_name.destroy
    if @extra_field_name.destroy
      flash[:notice] = 'Field Name Deleted Successfully.'
      redirect_to extra_field_names_path
    else
      flash.now[:notice] = 'Field Name not Deleted.'
      render extra_field_names_path
    end
  end

  private

  def extra_field_name_params
    params.require(:extra_field_name).permit(:field_name, :table_name, :field_type,
                                              extra_field_options_attributes: %i[ option_name ])
  end
end
