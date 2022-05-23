class CreateJobStatus < ActiveRecord::Migration[6.1]
  def change
    create_table :job_statuses do |t|
      t.string :name
      t.string :status
      t.string :job_id
      t.json :arguments
      t.datetime :perform_in

      t.timestamps
    end
  end
end
