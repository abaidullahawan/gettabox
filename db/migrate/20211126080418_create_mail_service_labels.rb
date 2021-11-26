class CreateMailServiceLabels < ActiveRecord::Migration[6.1]
  def change
    create_table :mail_service_labels do |t|
      t.references :mail_service_role
      t.references :courier
      t.float :weight
      t.float :height
      t.float :width
      t.float :length
      t.text :product_ids

      t.timestamps
    end
  end
end
