# frozen_string_literal: true

# Multiple File Mapping Job
class MultiFileMappingJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    spreadsheet1 = _args.last[:spreadsheet1]
    spreadsheet2 = _args.last[:spreadsheet2]
    mapping = _args.last[:mapping]
    id = _args.last[:multifile_mapping_id]
    multifile = MultifileMapping.find_by(id: id)
    spreadsheet1 = CSV.parse(spreadsheet1, headers: true)
    spreadsheet2 = CSV.parse(spreadsheet2, headers: true)
    attributes = mapping.data_to_print
    attribute_data = []
    attributes.each do |attribute|
      attribute_data.push(attribute.gsub('_', ' '))
    end
    matchable = mapping.mapping_data.select { |_, v| v.present? && v != '' }

    # file = Tempfile.new(['Mapped-File', '.csv'])
    # begin
      # @csv = CSV.generate(headers: true) do |csv|
      name = "multi-mapping--#{multifile.created_at.strftime('%d-%m-%Y @ %H:%M:%S')}"
      csv = CSV.open("/home/deploy/channeldispatch/current/tmp/#{name}", "wb") do |csv|
        csv << attributes
        non_matching1 = []
        non_matching2 = []
        matching1 = []
        matching = []
        if mapping.mapping_rule.present?
          case_sensitivity(spreadsheet1, spreadsheet2, matchable, mapping, csv, attribute_data)
        else
          spreadsheet1.each do |record1|
            matchable.each do |matched|
              matching = spreadsheet2.select { |row| row if record1[matched[0].gsub('_', ' ')] == row[matched[1].gsub('_', ' ')]}
              next non_matching1 << [record1] unless matching.present?

              row1 = record1.values_at(*attribute_data).compact
              row2 = matching.first.values_at(*attribute_data).compact
              row = row1 + row2
              csv << row
              matching1 << matching
            end
          end
          unmatch_csv_data(spreadsheet2, matching1, non_matching2, non_matching1, csv, attributes)
        end
      end
    # ensure
    #   file.close
    # end
    # byebug
    # @multifile_mapping.update(
    #   attach_csv: ActionDispatch::Http::UploadedFile.new(
    #     tempfile: File.open("tmp/csv_cache/#{name}"),
    #     filename: "#{name}",content_type: '.csv'
    #   )
    # )
    # @multifile_mapping.attach_csv.attach = file.path
    # @multifile_mapping.save
    multifile.update(download: true)
  end

  def case_sensitivity(spreadsheet1, spreadsheet2, matchable, mapping, csv, attribute_data)
    matching = []
    non_matching1 = []
    non_matching2 = []
    spreadsheet1.each do |record1|
      spreadsheet2.each do |record2|
        matchable.each do |matched|
          if symbol_case(record1, record2, matched, mapping) || space_case(record1, record2, matched, mapping) || upper_case(record1, record2, matched, mapping)
            row1 = record1.values_at(*attribute_data).compact
            row2 = record2.values_at(*attribute_data).compact
            matching << [record1]
            matching << [record2]
            row = row1 + row2
            csv << row
          end
        end
      end
    end
    unmatch_csv_data_spreadsheat1(spreadsheet1, matching, non_matching1)
    unmatch_csv_data(spreadsheet2, matching, non_matching2, non_matching1, csv, attribute_data)
  end

  def symbol_case(record1, record2, matched, mapping)
    true unless mapping.mapping_rule.include?('symbol_case')

    if record1[matched[0]].gsub('_',' ')&.gsub(/[^0-9A-Za-z]/, '')== record2[matched[1].gsub('_',' ')]&.gsub(/[^0-9A-Za-z]/, '')
      true
    else
      false
    end
  end

  def space_case(record1, record2, matched, mapping)
    true unless mapping.mapping_rule.include?('space_case')

    if record1[matched[0]].gsub('_',' ')&.delete(' ') == record2[matched[1].gsub('_', ' ')]&.delete(' ')
      true
    else
      false
    end
  end

  def upper_case(record1, record2, matched, mapping)
    true unless mapping.mapping_rule.include?('upper_case')

    if record1[matched[0]].gsub('_', ' ')&.casecmp(record2[matched[1].gsub('_', ' ')])&.zero?
      true
    else
      false
    end
  end

  def unmatch_csv_data_spreadsheat1(spreadsheet1, matching, non_matching1)
    spreadsheet1.each do |record1|
      matching.each do |row|
        non_matching1 << [record1] if record1 != row
      end
    end
  end

  def unmatch_csv_data(spreadsheet2, matching1, non_matching2, non_matching1, csv, attribute_data)
    spreadsheet2.each do |record2|
      matching1.each do |row|
        non_matching2 << [record2] if record2 != row
      end
    end
    unmatched = (non_matching2 + non_matching1 - matching1).uniq
    unmatched.each do |un|
      csv << un.first.values_at(*attribute_data)
    end
  end
end
