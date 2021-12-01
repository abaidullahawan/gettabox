class RemoveTableFulfilmentInstruction < ActiveRecord::Migration[6.1]
  def change
    drop_table :fulfillment_instructions
  end
end
