class ChangeReferenceColumnAttributeSettings < ActiveRecord::Migration[6.1]
  def change
    change_column :attribute_settings, :user_id, :bigint, null: true
  end
end
