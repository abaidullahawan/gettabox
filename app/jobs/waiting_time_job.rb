# frozen_string_literal: true

# orders for amazon
class WaitingTimeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    job_status_id = _args.last[:job_status_id]
    job_status = JobStatus.find_by(id: job_status_id)
    return unless job_status.present? || job_status.status_busy?

    arguments = job_status.arguments.nil? ? {} : job_status.arguments
    if job_status.name.downcase.include? 'amazon'
      job = job_status.name.constantize.set(wait: elapsed_seconds.seconds).perform_later(arguments.merge(job_status_id: job_status_id))
      job_status.update( job_id: job.job_id, status: 'inqueue')
    else
      job = job_status.name.constantize.perform_later(arguments.merge(job_status_id: job_status_id), status: 'inqueue')
      job_status.update( job_id: job.job_id)
    end
  end

end
