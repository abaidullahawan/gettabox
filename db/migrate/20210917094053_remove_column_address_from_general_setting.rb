class RemoveColumnAddressFromGeneralSetting < ActiveRecord::Migration[6.1]
  def change
    remove_column :general_settings, :address

  end
end
