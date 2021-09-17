class CreateAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :addresses do |t|
      t.string :company
      t.string :address
      t.string :city
      t.string :region
      t.string :postcode
      t.string :country
      t.references :addressable, polymorphic: true
      t.timestamps
    end
  end
end
