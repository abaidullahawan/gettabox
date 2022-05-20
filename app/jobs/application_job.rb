# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base # :nodoc:
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  before_enqueue :enqueued
  before_perform :performing
  after_perform :proccessed

  def enqueued
    job = JobStatus.find_or_create_by(job_id: job_id, name: self.class.to_s)
    job.update(status: 'Queued')
    job.update(arguments: arguments.first) if job.arguments.nil?
  end

  def performing
    job = JobStatus.find_or_create_by(job_id: job_id, name: self.class.to_s)
    job.update(status: 'Busy')
    job.update(arguments: arguments.first) if job.arguments.nil?
  end

  def proccessed
    job = JobStatus.find_or_create_by(job_id: job_id, name: self.class.to_s)
    job.update(status: 'Processed')
  end
end
