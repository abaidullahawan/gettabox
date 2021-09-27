class CreateExtraFieldValues < ActiveRecord::Migration[6.1]
  def change
    create_table :extra_field_values do |t|
      t.json :field_value
      t.references :fieldvalueable, polymorphic: true
      t.timestamps
    end
  end
end
