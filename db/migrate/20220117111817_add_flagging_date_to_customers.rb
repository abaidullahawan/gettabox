class AddFlaggingDateToCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :system_users, :flagging_date, :datetime
  end
end
