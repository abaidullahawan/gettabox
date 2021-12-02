class CreateRule < ActiveRecord::Migration[6.1]
  def change
    create_table :rules do |t|
      t.integer :rule_field
      t.integer :rule_operator
      t.text :rule_value
      t.boolean :is_optional
      t.references :mail_service_rule

      t.timestamps
    end
  end
end
