class CreateWorkDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :work_details do |t|
      t.string :company_name
      t.string :position
      t.string :city
      t.text :description
      t.boolean :currently_working
      t.date :from
      t.date :to
      t.references :personal_detail

      t.timestamps
    end
  end
end
