# frozen_string_literal: true

# AddCsvDataToDbJob
class AddCsvDataToDbJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    filename1 = _args.last[:filename1]
    filename2 = _args.last[:filename2]
    mapping_id = _args.last[:mapping_id]
    multifile_mapping_id = _args.last[:multifile_mapping_id]
    spreadsheet1 = CSV.parse(open_spreadsheet(filename1))
    spreadsheet2 = CSV.parse(open_spreadsheet(filename2))
    headers1 = spreadsheet1.first
    headers2 = spreadsheet2.first
    headers1.each_with_index do |header, index|
      FileOne.first.update("column_#{index}": header)
    end
    headers2.each_with_index do |header, index|
      FileTwo.first.update("column_#{index}": header)
    end
    job_id = FileOne.first.job_id
    spreadsheet1.drop(1).each do |record|
      file_one = FileOne.create(job_id: job_id)
      record.each_with_index do |data, index|
        file_one.update("column_#{index}": data, filename: 'file1')
      end
    end
    spreadsheet2.drop(1).each do |record|
      file_two = FileTwo.create(job_id: job_id)
      record.each_with_index do |data, index|
        file_two.update("column_#{index}": data, filename: 'file2')
      end
    end
    delete_files(filename1)
    delete_files(filename2)
    job_data = MultiFileMappingJob.perform_later(mapping_id: mapping_id, multifile_mapping_id: multifile_mapping_id)
    JobStatus.create(job_id: job_data.job_id, name: 'MultiFileMappingJob', status: 'Queued',
      arguments: { mapping_id: mapping_id, multifile_mapping_id: multifile_mapping_id })
  end

  def open_spreadsheet(filename)
    File.read(Rails.root.join('tmp', filename)).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
  end

  def delete_files(filename)
    File.delete(Rails.root.join('tmp', filename))
  end
end
