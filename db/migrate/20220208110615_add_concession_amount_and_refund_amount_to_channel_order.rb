class AddConcessionAmountAndRefundAmountToChannelOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_orders, :concession_amount, :string
    add_column :channel_orders, :refund_amount, :string
  end
end
