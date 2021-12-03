class ChangeColumnTypeInRules < ActiveRecord::Migration[6.1]
  def change
    change_column :rules, :rule_field, :string
    change_column :rules, :rule_operator, :string
  end
end
