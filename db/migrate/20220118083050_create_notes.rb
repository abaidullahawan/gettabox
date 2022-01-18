class CreateNotes < ActiveRecord::Migration[6.1]
  def change
    create_table :notes do |t|
      t.string :message
      t.references :user
      t.references :reference, polymorphic: true

      t.timestamps
    end
  end
end
