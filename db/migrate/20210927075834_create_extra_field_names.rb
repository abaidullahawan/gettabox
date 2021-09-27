class CreateExtraFieldNames < ActiveRecord::Migration[6.1]
  def change
    create_table :extra_field_names do |t|
      t.json :field_name
      t.references :fieldnameable, polymorphic: true
      t.timestamps
    end
  end
end
