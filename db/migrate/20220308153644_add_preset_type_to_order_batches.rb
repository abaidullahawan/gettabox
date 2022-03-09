class AddPresetTypeToOrderBatches < ActiveRecord::Migration[6.1]
  def change
    add_column :order_batches, :preset_type, :integer
  end
end
