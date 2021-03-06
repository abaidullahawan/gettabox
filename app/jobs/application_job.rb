# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base # :nodoc:
  sidekiq_options retry: 0
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # before_enqueue :enqueued
  before_perform :performing
  after_perform :proccessed

  def enqueued
    job = JobStatus.find_or_create_by(job_id: job_id, name: self.class.to_s)
    job.update(status: 'inqueue')
    job.update(arguments: arguments.first) if job.arguments.nil?
  end

  def performing
    return unless arguments.first.try(:[], :job_status_id).present? && !(self.class.eql? WaitingTimeJob)

    job_status_id = arguments.first.try(:[], :job_status_id)
    job = JobStatus.find_by(id: job_status_id)
    job&.update(status: 'busy')
    job&.update(arguments: arguments.first) if job&.arguments.nil?
  end

  def proccessed
    return unless arguments.first.try(:[], :job_status_id).present? && !(self.class.eql? WaitingTimeJob)

    job_status_id = arguments.first.try(:[], :job_status_id)
    job = JobStatus.find_by(id: job_status_id)
    job.update(status: 'processed') if job.present?
  end
end
