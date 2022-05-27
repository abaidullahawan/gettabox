# frozen_string_literal: true

# AddCsvDataToDbJob
class AddCsvDataToDbJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    filename1 = _args.last[:filename1]
    filename2 = _args.last[:filename2]
    mapping_id = _args.last[:mapping_id]
    multifile_mapping_id = _args.last[:multifile_mapping_id]
    multifile = MultifileMapping.find_by(id: multifile_mapping_id)
    mapping_headers = ImportMapping.find(mapping_id).mapping_data.compact_blank
    spreadsheet1 = CSV.parse(open_spreadsheet(filename1))
    spreadsheet2 = CSV.parse(open_spreadsheet(filename2))
    headers1 = spreadsheet1.first
    headers2 = spreadsheet2.first
    headers1.map! {|v| v&.gsub('_', ' ').gsub(' ', '_') }
    headers2.map! {|v| v&.gsub('_', ' ').gsub(' ', '_') }
    array1 = Array.new(headers1.count) { |i| "column_#{i}"}
    array2 = Array.new(headers2.count) { |i| "column_#{i}"}
    headers1 = Hash[array1.zip headers1]
    headers2 = Hash[array2.zip headers2]
    FileOne.where(filename: filename1).first.update(headers1)
    FileTwo.where(filename: filename2).first.update(headers2)
    column_name1 = FileOne.where(filename: filename1).first.attributes.compact_blank.invert[mapping_headers.keys.first]
    spreadsheet1.drop(1).each do |record|
      hash = Hash[array1.zip record]
      value = hash[column_name1]
      hash[column_name1] = value&.gsub(/[^0-9A-Za-z]/, '')&.upcase
      file_one = FileOne.create(filename: filename1)
      file_one.update(hash)
    end
    column_name2 = FileTwo.where(filename: filename2).first.attributes.compact_blank.invert[mapping_headers.values.first]
    spreadsheet2.drop(1).each do |record|
      hash = Hash[array2.zip record]
      value = hash[column_name2]
      hash[column_name2] = value&.gsub(/[^0-9A-Za-z]/, '')&.upcase
      file_two = FileTwo.create(filename: filename2)
      file_two.update(hash)
    end
    delete_files(filename1)
    delete_files(filename2)
    job_data = MultiFileMappingJob.perform_later(
      mapping_id: mapping_id, multifile_mapping_id: multifile_mapping_id,
      filename1: filename1, filename2: filename2
    )
    # JobStatus.create(job_id: job_data.job_id, name: 'MultiFileMappingJob', status: 'inqueue',
    #   arguments: { mapping_id: mapping_id, multifile_mapping_id: multifile_mapping_id }, perform_in: 300)

  rescue StandardError => e
    delete_record(filename1, filename2)
    multifile.update(error: e, download: false)
  end

  def open_spreadsheet(filename)
    File.read(Rails.root.join('tmp', filename)).force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
  end

  def delete_files(filename)
    File.delete(Rails.root.join('tmp', filename))
  end

  def delete_record(filename1, filename2)
    FileOne.where(filename: filename1).delete_all
    FileTwo.where(filename: filename2).delete_all
  end
end
