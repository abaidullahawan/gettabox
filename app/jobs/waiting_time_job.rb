# frozen_string_literal: true

# orders for amazon
class WaitingTimeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    byebug
    job_status_id = _args.last[:job_status_id] || _args.last['job_status_id']
    job_status = JobStatus.find_by(id: job_status_id)
    return unless job_status.present? && job_status.status_busy?

    arguments = job_status.arguments.nil? ? {} : job_status.arguments
    job = job_status.name.constantize.set(wait: job_status.perform_in.seconds).perform_later(arguments.merge(job_status_id: job_status_id))
    job_status.update( job_id: job.job_id, status: 'inqueue')
  end

end
