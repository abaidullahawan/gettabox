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
        flash[:notice] = 'File Upload Successful!'
      end
      redirect_to import_mappings_path
  end

  private

  def csv_create_records(csv)
    csv.each do |row|
      if row['ebayorder_id'].nil?
        @order_id = row['channel_order_id']
      else
        order = ChannelOrder.find_by(ebayorder_id: row['ebayorder_id'])
        @order_id = order.id if order.present?
      end
      tracking_numbers = row['tracking_no'].split(',')
      tracking_numbers.each do |number|
        tracking = Tracking.find_or_initialize_by(tracking_no: number, channel_order_id: @order_id)
        tracking.save
      end
    end
  end

end