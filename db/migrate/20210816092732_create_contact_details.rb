class CreateContactDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :contact_details do |t|
      t.string :phone_number
      t.string :email
      t.string :street_address
      t.string :city
      t.string :province
      t.string :country
      t.integer :zip
      t.references :personal_detail

      t.timestamps
    end
  end
end
