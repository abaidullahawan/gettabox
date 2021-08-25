class ChangeColumnNameAttributeSettings < ActiveRecord::Migration[6.1]
  def change
    rename_column :attribute_settings, :type, :setting_type
  end
end
