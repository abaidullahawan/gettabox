class AddAddressTitleToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :address_title, :string
  end
end
