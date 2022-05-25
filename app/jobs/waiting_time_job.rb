# frozen_string_literal: true

# orders for amazon
class WaitingTimeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    job_status_id = _args.last[:job_status_id]
    job_status = JobStatus.find_by(id: job_status_id)
    return unless job_status.status_busy?

    arguments = job_status.arguments.nil? ? {} : job_status.arguments
    if job_status.name.downcase.include? 'amazon'
      elapsed_seconds = set_elapsed_seconds
      job = job_status.name.constantize.set(wait: elapsed_seconds.seconds).perform_later(arguments.merge(job_status_id: job_status_id))
      job_status.update( job_id: job.job_id, perform_in: Time.zone.now + elapsed_seconds.seconds, status: 'inqueue')
    else
      job = job_status.name.constantize.perform_later(arguments.merge(job_status_id: job_status_id), status: 'inqueue')
      job_status.update( job_id: job.job_id)
    end
  end

  def set_elapsed_seconds
    credential = Credential.find_or_create_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = Time.zone.now > wait_time ? Time.zone.now + 130.seconds : wait_time + 130.seconds
    credential.update(redirect_uri: 'AmazonJob', created_at: wait_time)
    wait_time - Time.zone.now
  end
end
