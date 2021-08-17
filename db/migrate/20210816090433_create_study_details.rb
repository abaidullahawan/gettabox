class CreateStudyDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :study_details do |t|
      t.string :school
      t.string :degree
      t.integer :format
      t.text :description
      t.date :from
      t.date :to
      t.references :personal_detail

      t.timestamps
    end
  end
end
