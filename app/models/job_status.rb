# frozen_string_literal: true

# Job Status
class JobStatus < ApplicationRecord
  after_create :waiting_job_create

  enum status: {
    inqueue: 'inqueue',
    retry: 'retry',
    busy: 'busy',
    processed: 'processed',
    cancelled: 'cancelled'
  }, _prefix: true

  def self.sec_to_hours(sec)
    '%02d:%02d:%02d' % [sec / 3600, sec / 60 % 60, sec % 60]
  end

  def self.sec_to_minutes(sec)
    "%02d:%02d" % [sec / 60 % 60, sec % 60]
  end

  ransacker :arguments do |parent|
    Arel::Nodes::InfixOperation.new('||',
      parent.table[:arguments], Arel::Nodes.build_quoted(' ')
    )
  end

  private

  def waiting_job_create
    return if $request&.url&.include? 'auto_dispatch'

    WaitingTimeJob.perform_later(job_status_id: id)
  end
end
