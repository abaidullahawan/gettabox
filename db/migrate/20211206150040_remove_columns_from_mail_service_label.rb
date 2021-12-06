class RemoveColumnsFromMailServiceLabel < ActiveRecord::Migration[6.1]
  def change
    change_table :mail_service_labels do |t|
      t.remove_references :courier, index: true
      t.remove :product_ids
      t.remove_references :mail_service_rule, index: true
      t.references :assign_rule
    end
  end
end
