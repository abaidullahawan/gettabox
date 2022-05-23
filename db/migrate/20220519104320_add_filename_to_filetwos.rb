class AddFilenameToFiletwos < ActiveRecord::Migration[6.1]
  def change
    add_column :file_twos, :filename, :string
  end
end
