class CreatePurchaseDeliveries < ActiveRecord::Migration[6.1]
  def change
    create_table :purchase_deliveries do |t|
      t.belongs_to :purchase_order, null: false, foreign_key: true
      t.decimal :total_bill

      t.timestamps
    end
  end
end
