class ChangeSystemUsersFields < ActiveRecord::Migration[6.1]
  def change
    change_table :system_users do |t|
      t.string :name
      t.integer :delivery_method
      t.integer :payment_method
      t.integer :days_for_payment
      t.integer :days_for_order_to_completion
      t.integer :days_for_completion_to_delivery
      t.string :currency_symbol
      t.decimal :exchange_rate
    end
  end
end
