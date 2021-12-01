class AddReplicaColumnsInMailServiceRules < ActiveRecord::Migration[6.1]
  def change
    change_table :mail_service_rules do |t|
      t.remove :description
      t.text :rule_name
      t.float :public_cost
      t.float :initial_weight
      t.float :additonal_cost_per_kg
      t.float :vat_percentage
      t.integer :label_type
      t.integer :csv_file
      t.integer :courier_account
      t.integer :rule_naming_type
      t.integer :manual_dispatch_label_template
      t.integer :priority_delivery_days
      t.boolean :is_priority
      t.integer :estimated_delivery_days
      t.references :courier
      t.references :service
      t.integer :print_queue_type
      t.integer :additional_label
      t.integer :pickup_address
      t.integer :bonus_score
      t.float :base_weight
      t.float :base_weight_max
    end
  end
end
