class CreateFulfillmentInstructions < ActiveRecord::Migration[6.1]
  def change
    create_table :fulfillment_instructions do |t|
      t.string :shipping_service_code
      t.json :fulfillment_data
      t.references :channel_order
      t.timestamps
    end
  end
end
