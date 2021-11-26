class CreateMailServiceRules < ActiveRecord::Migration[6.1]
  def change
    create_table :mail_service_rules do |t|
      t.string :description
      t.string :service_name

      t.timestamps
    end
  end
end
