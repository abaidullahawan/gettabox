class AddFilenameToFileones < ActiveRecord::Migration[6.1]
  def change
    add_column :file_ones, :filename, :string
  end
end
