# frozen_string_literal: true

# Order Tracking
class TrackingsController < ApplicationController
  include ImportExport

  before_action :klass_import, only: %i[import]

  def create
    # byebug
  end

  def new
    # byebug
  end

  def import
    if @csv.present?
      @csv.delete('id')
      @csv.delete('created_at')
      @csv.delete('updated_at')
      csv_create_records(@csv)
      # flash[:notice] = 'File Upload Successful!'
    end
  end

  private

  def csv_create_records(csv)
    rows = []
    csv.each do |row|
      order_id = row['order_id'].nil? ? row['channel_order_id'] : ChannelOrder.find_by(order_id: row['order_id'])&.id
      tracking_numbers = row['tracking_no'].split(',')
      message = []
      tracking_numbers.each do |number|
        tracking = Tracking.find_or_initialize_by(tracking_no: number, channel_order_id: order_id)
        note = tracking.save ? 'Tracking uploaded successfully' : tracking.errors.full_messages
        message << note
      end
      row = row.to_h.reject { |key, _| key.nil? }
      row['message'] = message
      rows << row
    end
    generate_csv(rows)
  end

  def generate_csv(rows)
    @csv = CSV.generate(headers: true) do |csv|
      csv << rows.first.keys
      rows.each do |row|
        csv << row.values
      end
    end
    request.format = 'csv'
    respond_to do |format|
      format.csv { send_data @csv, filename: "tracking-reponse-#{Date.today}.csv" }
    end
  end
end
