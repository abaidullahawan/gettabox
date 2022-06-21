class ChangeDataTypeFromDecimalToInteger < ActiveRecord::Migration[6.1]
  def self.up
    change_column :multipack_products, :quantity, :integer

    change_column :products, :total_stock, :integer
    change_column :products, :fake_stock, :integer
    change_column :products, :pending_orders, :integer
    change_column :products, :allocated_orders, :integer
    change_column :products, :available_stock, :integer
    change_column :products, :allocated, :integer

    change_column :channel_products, :item_quantity, :integer

  end

  def self.down
    change_column :multipack_products, :quantity, :decimal

    change_column :products, :total_stock, :decimal
    change_column :products, :fake_stock, :decimal
    change_column :products, :pending_orders, :decimal
    change_column :products, :allocated_orders, :decimal
    change_column :products, :available_stock, :decimal
    change_column :products, :allocated, :float

    change_column :channel_products, :item_quantity, :decimal

  end
end
