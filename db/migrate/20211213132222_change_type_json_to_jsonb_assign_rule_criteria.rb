class ChangeTypeJsonToJsonbAssignRuleCriteria < ActiveRecord::Migration[6.1]
  def change
    change_column(:assign_rules, :criteria, :jsonb)
  end
end
