class AddFieldsToGeneralSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :general_settings, :vat_reg_no, :string
    add_column :general_settings, :company_reg_no, :string
  end
end
