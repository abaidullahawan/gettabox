class AddFulfillmentInstructionInChannelOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :fulfillment_instruction, :string
  end
end
