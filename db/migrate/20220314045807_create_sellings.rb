class CreateSellings < ActiveRecord::Migration[6.1]
  def change
    create_table :sellings do |t|
      t.string :name
      t.integer :quantity

      t.timestamps
    end
  end
end
