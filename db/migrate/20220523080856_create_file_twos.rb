class CreateFileTwos < ActiveRecord::Migration[6.1]
  def change
    create_table :file_twos do |t|
      t.string :job_id
      50.times do |i|
        t.string :"column_#{i}"
      end
      t.string :filename
      t.timestamps
    end
  end
end
