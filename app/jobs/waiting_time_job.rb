# frozen_string_literal: true

# orders for amazon
class WaitingTimeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    job_status_id = _args.last[:job_status_id]
    job_status = JobStatus.find_by(id: job_status_id)
    return unless job_status.status_inqueue?

    job_status.update(status: 'busy')
    if job_status.name.downcase.include? 'amazon'
      elapsed_seconds = set_elapsed_seconds
      arguments = job_status.arguments.nil? ? {} : job_status.arguments
      job_status.name.constantize.set(wait: elapsed_seconds.seconds).perform_later(arguments.merge(job_status_id: job_status_id))
    else
      job_status.name.constantize.perform_later(arguments.merge(job_status_id: job_status_id))
    end
  end

  def set_elapsed_seconds
    credential = Credential.find_or_create_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = DateTime.now > wait_time ? DateTime.now + 130.seconds : wait_time + 130.seconds
    credential.update(redirect_uri: 'AmazonJob', created_at: wait_time)
    wait_time - DateTime.now
  end
end
