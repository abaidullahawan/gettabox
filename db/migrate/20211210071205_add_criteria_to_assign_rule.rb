class AddCriteriaToAssignRule < ActiveRecord::Migration[6.1]
  def change
    add_column :assign_rules, :criteria, :json
  end
end
