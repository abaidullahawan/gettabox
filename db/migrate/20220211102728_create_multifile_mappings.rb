class CreateMultifileMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :multifile_mappings do |t|
      t.string :file1
      t.string :file2
      t.boolean :download

      t.timestamps
    end
  end
end
