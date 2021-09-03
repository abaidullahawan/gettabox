class CreatePurchaseOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :purchase_orders do |t|
      t.references :supplier
      t.decimal :total_bill

      t.timestamps
    end
  end
end
