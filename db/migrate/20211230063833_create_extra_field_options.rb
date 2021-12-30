class CreateExtraFieldOptions < ActiveRecord::Migration[6.1]
  def change
    create_table :extra_field_options do |t|
      t.references :extra_field_name
      t.string :option_name
      
      t.timestamps
    end
  end
end
