class AddSubTypeAndErrorToMultifileMappings < ActiveRecord::Migration[6.1]
  def change
    add_column :multifile_mappings, :sub_type, :string
    add_column :multifile_mappings, :error, :string
  end
end
