# frozen_string_literal: true

# Multiple File Mapping Job
class MultiFileMappingJob < ApplicationJob
  queue_as :default
  # require 'creek'

  def perform(*_args)
    mapping_id = _args.last[:mapping_id]
    id = _args.last[:multifile_mapping_id]
    mapping = ImportMapping.find(mapping_id)
    multifile = MultifileMapping.find_by(id: id)
    attributes = mapping.data_to_print
    matchable = mapping.mapping_data.select { |_, v| v.present? && v != '' }
    name = "multi-mapping--#{multifile.created_at.strftime('%d-%m-%Y @ %H:%M:%S')}"
    # book = Spreadsheet::Workbook.new
    # sheet = book.create_worksheet
    # sheet.row(0).concat attributes
    # index = 1
    CSV.open("/home/deploy/channeldispatch/current/public/uploads/#{name}", 'wb') do |csv|
      csv << attributes
      if mapping.mapping_rule.present?
        case_sensitivity(matchable, csv, attributes)
      else
        non_case_sensitivity(matchable, csv, attributes)
      end
    end

    multifile.update(download: true)
    # book.write "/home/ali/Projects/gettabox/public/uploads/#{name}.xls"

    FileOne.delete_all
    FileTwo.delete_all

  rescue StandardError => e
    multifile.update(error: e, download: false)
  end

  def case_sensitivity(matchable, csv, attributes)
    matching1 = []
    non_matching1 = []
    matching2 = []
    non_matching2 = []
    record1 = []
    record2 = []
    record3 = []
    record4 = []

    hash = FileOne.first.attributes.compact_blank.excluding('id', 'job_id', 'filename')
    column_name1 = hash.invert[matchable.first.first]
    headers1 = hash.invert.keys
    hash = FileTwo.first.attributes.compact_blank.excluding('id', 'job_id', 'filename')
    column_name2 = hash.invert[matchable.first.last]
    headers2 = hash.invert.keys

    query = "(Select REGEXP_REPLACE(#{column_name1}, '[^A-Za-z0-9]', '', 'g') from file_ones OFFSET 1) Intersect
            (Select REGEXP_REPLACE(#{column_name2}, '[^A-Za-z0-9]', '', 'g') from file_twos OFFSET 1)"
    matched_data = ActiveRecord::Base.connection.exec_query(query).rows&.flatten

    match_data_for_one = FileOne.where("REGEXP_REPLACE(#{column_name1}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data)
    unmatch_data_for_one = FileOne.where.not("REGEXP_REPLACE(#{column_name1}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data).without(FileOne.first)
    match_data_for_two = FileTwo.where("REGEXP_REPLACE(#{column_name2}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data)
    unmatch_data_for_two = FileTwo.where.not("REGEXP_REPLACE(#{column_name2}, '[^A-Za-z0-9]', '', 'g') IN (?)", matched_data).without(FileTwo.first)

    match_data_for_one.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename')
      matching1 << matched unless matched.empty?
    end
    unmatch_data_for_one.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename')
      non_matching1 << unmatched unless unmatched.empty?
    end

    match_data_for_two.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename')
      matching2 << matched unless matched.empty?
    end
    unmatch_data_for_two.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename')
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
      # sheet.row(index).concat row.values_at(*attributes)
      # index += 1
      csv << row.values_at(*attributes)
    end
    record3.each do |row|
      # sheet.row(index).concat row.values_at(*attributes)
      # index += 1
      csv << row.values_at(*attributes)
    end
    record4.each do |row|
      # sheet.row(index).concat row.values_at(*attributes)
      # index += 1
      csv << row.values_at(*attributes)
    end
  end

  def non_case_sensitivity(matchable, csv, attributes)
    matching1 = []
    non_matching1 = []
    matching2 = []
    non_matching2 = []
    record1 = []
    record2 = []
    record3 = []
    record4 = []

    hash = FileOne.first.attributes.compact_blank.excluding('id', 'job_id', 'filename')
    column_name1 = hash.invert[matchable.first.first]
    headers1 = hash.invert.keys
    hash = FileTwo.first.attributes.compact_blank.excluding('id', 'job_id', 'filename')
    column_name2 = hash.invert[matchable.first.last]
    headers2 = hash.invert.keys

    query = "(Select #{column_name1} from file_ones OFFSET 1) Intersect (Select #{column_name2} from file_twos OFFSET 1)"
    matched_data = ActiveRecord::Base.connection.exec_query(query).rows&.flatten

    match_data_for_one = FileOne.where("#{column_name1} IN (?)", matched_data)
    unmatch_data_for_one = FileOne.where.not("#{column_name1} IN (?)", matched_data).without(FileOne.first)
    match_data_for_two = FileTwo.where("#{column_name2} IN (?)", matched_data)
    unmatch_data_for_two = FileTwo.where.not("#{column_name2} IN (?)", matched_data).without(FileTwo.first)

    match_data_for_one.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename')
      matching1 << matched unless matched.empty?
    end
    unmatch_data_for_one.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename')
      non_matching1 << unmatched unless unmatched.empty?
    end

    match_data_for_two.each do |matched|
      matched = matched.attributes.excluding('id', 'job_id', 'filename')
      matching2 << matched unless matched.empty?
    end
    unmatch_data_for_two.each do |unmatched|
      unmatched = unmatched.attributes.excluding('id', 'job_id', 'filename')
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
      # sheet.row(index).concat row.values_at(*attributes)
      # index += 1
      csv << row.values_at(*attributes)
    end
    record3.each do |row|
      # sheet.row(index).concat row.values_at(*attributes)
      # index += 1
      csv << row.values_at(*attributes)
    end
    record4.each do |row|
      # sheet.row(index).concat row.values_at(*attributes)
      # index += 1
      csv << row.values_at(*attributes)
    end
  end
end
