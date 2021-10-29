class CreateCredential < ActiveRecord::Migration[6.1]
  def change
    create_table :credentials do |t|
      t.string :redirect_uri
      t.string :grant_type
      t.text :authorization

      t.timestamps
    end
  end
end
