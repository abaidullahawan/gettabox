class AddCarrierAndServiceToTrackings < ActiveRecord::Migration[6.1]
  def change
    add_column :trackings, :carrier, :string
    add_column :trackings, :service, :string
    add_column :trackings, :shipping_service, :string
  end
end
