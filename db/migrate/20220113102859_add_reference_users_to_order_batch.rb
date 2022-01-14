class AddReferenceUsersToOrderBatch < ActiveRecord::Migration[6.1]
  def change
    add_reference :order_batches, :user
  end
end
