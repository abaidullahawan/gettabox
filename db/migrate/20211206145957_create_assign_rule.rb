class CreateAssignRule < ActiveRecord::Migration[6.1]
  def change
    create_table :assign_rules do |t|
      t.references :mail_service_rule
      t.boolean :save_later
      t.integer :status
      t.text :product_ids

      t.timestamps
    end
  end
end
