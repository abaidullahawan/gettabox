# frozen_string_literal: true

# Multiple File Mapping Job
class MultiFileMappingJob < ApplicationJob
  queue_as :default
  # require 'creek'

  def perform(*_args)
    mapping_id = _args.last[:mapping_id]
    id = _args.last[:multifile_mapping_id]
    filename1 = _args.last[:filename1]
    filename2 = _args.last[:filename2]
    mapping = ImportMapping.find(mapping_id)
    multifile = MultifileMapping.find_by(id: id)
    attributes = mapping.data_to_print
    matchable = mapping.mapping_data.select { |_, v| v.present? && v != '' }
    matchable_data = []
    attribute_data = []
    matchable.to_a.flatten.each do |attribute|
      matchable_data.push(attribute.gsub('_', ' ').gsub(' ', '_'))
    end
    attributes.each do |attribute|
      attribute_data.push(attribute.gsub('_', ' ').gsub(' ', '_'))
    end
    name = "multi-mapping--#{multifile.created_at.strftime('%d-%m-%Y @ %H:%M:%S')}"

    CSV.open("/home/ali/Projects/gettabox/public/uploads/#{name}", 'wb') do |csv|
      csv << attributes
      if mapping.mapping_rule.present?
        case_sensitivity(csv, attribute_data, matchable_data, filename1, filename2)
      else
        non_case_sensitivity(csv, attribute_data, matchable_data, filename1, filename2)
      end
    end

    multifile.update(download: true)
    delete_record(filename1, filename2)

  rescue StandardError => e
    multifile.update(error: e, download: false)
    delete_record(filename1, filename2)
  end

  def case_sensitivity(csv, attribute_data, matchable_data, filename1, filename2)
    matching1 = []
    non_matching1 = []
    matching2 = []
    non_matching2 = []
    record1 = []
    record2 = []
    record3 = []
    record4 = []
    hash1 = {}
    hash2 = {}

    hash = FileOne.where(filename: filename1).first.attributes.compact_blank.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
    hash.each do |k, v|
      hash1[k] = v.gsub('_', ' ').gsub(' ', '_')
    end
    column_name1 = hash1.invert[matchable_data.first]
    headers1 = hash1.invert.keys

    hash = FileTwo.where(filename: filename2).first.attributes.compact_blank.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
    hash.each do |k, v|
      hash2[k] = v.gsub('_', ' ').gsub(' ', '_')
    end
    column_name2 = hash2.invert[matchable_data.last]
    headers2 = hash2.invert.keys

    query = "(Select REGEXP_REPLACE(#{column_name1}, '[^A-Za-z0-9]', '', 'g') from file_ones where file_ones.filename = '#{filename1}' OFFSET 1) Intersect (Select REGEXP_REPLACE(#{column_name2}, '[^A-Za-z0-9]', '', 'g') from file_twos where file_twos.filename = '#{filename2}' OFFSET 1)"
    matched_data = ActiveRecord::Base.connection.exec_query(query).rows&.flatten

    match_data_for_one = FileOne.where(filename: filename1).where("REGEXP_REPLACE(#{column_name1}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data)
    unmatch_data_for_one = FileOne.where(filename: filename1).where.not("REGEXP_REPLACE(#{column_name1}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data).without(FileOne.where(filename: filename1).first)
    match_data_for_two = FileTwo.where(filename: filename2).where("REGEXP_REPLACE(#{column_name2}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data)
    unmatch_data_for_two = FileTwo.where(filename: filename2).where.not("REGEXP_REPLACE(#{column_name2}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data).without(FileTwo.where(filename: filename2).first)

    match_data_for_one.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      matching1 << matched unless matched.empty?
    end
    unmatch_data_for_one.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      non_matching1 << unmatched unless unmatched.empty?
    end

    match_data_for_two.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      matching2 << matched unless matched.empty?
    end
    unmatch_data_for_two.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      non_matching2 << unmatched unless unmatched.empty?
    end

    matching1 = matching1.uniq
    matching2 = matching2.uniq
    non_matching1 = non_matching1.uniq
    non_matching2 = non_matching2.uniq

    matching1.each do |record|
      record1 << headers1.zip(record.values).to_h
    end
    matching2.each do |record|
      record2 << headers2.zip(record.values).to_h
    end
    matching = record1.zip(record2).map { |h1, h2| h1.merge(h2) }

    non_matching1.each do |record|
      record3 << headers1.zip(record.values).to_h
    end
    non_matching2.each do |record|
      record4 << headers2.zip(record.values).to_h
    end
    matching.each do |row|
      csv << row.values_at(*attribute_data).map! { |attr| attr.nil? ? ' ' : attr }
    end
    record3.each do |row|
      csv << row.values_at(*attribute_data).map! { |attr| attr.nil? ? ' ' : attr }
    end
    record4.each do |row|
      csv << row.values_at(*attribute_data).map! { |attr| attr.nil? ? ' ' : attr }
    end
  end

  def non_case_sensitivity(csv, attribute_data, matchable_data, filename1, filename2)
    matching1 = []
    non_matching1 = []
    matching2 = []
    non_matching2 = []
    record1 = []
    record2 = []
    record3 = []
    record4 = []
    hash1 = {}
    hash2 = {}

    hash = FileOne.where(filename: filename1).first.attributes.compact_blank.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
    hash.each do |k, v|
      hash1[k] = v.gsub('_', ' ').gsub(' ', '_')
    end
    column_name1 = hash1.invert[matchable_data.first]
    headers1 = hash1.invert.keys

    hash = FileTwo.where(filename: filename2).first.attributes.compact_blank.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
    hash.each do |k, v|
      hash2[k] = v.gsub('_', ' ').gsub(' ', '_')
    end
    column_name2 = hash2.invert[matchable_data.last]
    headers2 = hash2.invert.keys

    query = "(Select #{column_name1} from file_ones where filename = '#{filename1}' OFFSET 1) Intersect
      (Select #{column_name2} from file_twos where filename = '#{filename2}' OFFSET 1)"
    matched_data = ActiveRecord::Base.connection.exec_query(query).rows&.flatten

    match_data_for_one = FileOne.where(filename: filename1).where("#{column_name1} IN (?)", matched_data)
    unmatch_data_for_one = FileOne.where(filename: filename1).where.not("#{column_name1} IN (?)", matched_data).without(FileOne.where(filename: filename1).first)
    match_data_for_two = FileTwo.where(filename: filename2).where("#{column_name2} IN (?)", matched_data)
    unmatch_data_for_two = FileTwo.where(filename: filename2).where.not("#{column_name2} IN (?)", matched_data).without(FileTwo.where(filename: filename2).first)

    match_data_for_one.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      matching1 << matched unless matched.empty?
    end
    unmatch_data_for_one.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      non_matching1 << unmatched unless unmatched.empty?
    end

    match_data_for_two.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      matching2 << matched unless matched.empty?
    end
    unmatch_data_for_two.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename', 'created_at', 'updated_at')
      non_matching2 << unmatched unless unmatched.empty?
    end

    matching1 = matching1.uniq
    matching2 = matching2.uniq
    non_matching1 = non_matching1.uniq
    non_matching2 = non_matching2.uniq

    matching1.each do |record|
      record1 << headers1.zip(record.values).to_h
    end
    matching2.each do |record|
      record2 << headers2.zip(record.values).to_h
    end
    matching = record1.zip(record2).map { |h1, h2| h1.merge(h2) }

    non_matching1.each do |record|
      record3 << headers1.zip(record.values).to_h
    end
    non_matching2.each do |record|
      record4 << headers2.zip(record.values).to_h
    end

    matching.each do |row|
      csv << row.values_at(*attribute_data).map! { |attr| attr.nil? ? ' ' : attr }
    end
    record3.each do |row|
      csv << row.values_at(*attribute_data).map! { |attr| attr.nil? ? ' ' : attr }
    end
    record4.each do |row|
      csv << row.values_at(*attribute_data).map! { |attr| attr.nil? ? ' ' : attr }
    end
  end

  def delete_record(filename1, filename2)
    FileOne.where(filename: filename1).delete_all
    FileTwo.where(filename: filename2).delete_all
  end
end
