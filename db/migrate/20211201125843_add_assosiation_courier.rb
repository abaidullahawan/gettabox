class AddAssosiationCourier < ActiveRecord::Migration[6.1]
  def change
    remove_reference :services, :service
    add_reference :services, :courier
  end
end
