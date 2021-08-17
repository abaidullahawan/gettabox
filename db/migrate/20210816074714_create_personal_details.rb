class CreatePersonalDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :personal_details do |t|
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.date :dob
      t.integer :gender
      t.references :bio, polymorphic: true

      t.timestamps
    end
  end
end
