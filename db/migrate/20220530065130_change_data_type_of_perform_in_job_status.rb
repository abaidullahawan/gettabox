class ChangeDataTypeOfPerformInJobStatus < ActiveRecord::Migration[6.1]
  def up
    remove_column :job_statuses, :perform_in, :datetime
    add_column :job_statuses, :perform_in, :integer
  end

  def down
    add_column :job_statuses, :perform_in, :datetime
    remove_column :job_statuses, :perform_in, :integer
  end
end
