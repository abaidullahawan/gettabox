# frozen_string_literal: true

# orders for amazon
class WaitingTimeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    tracking_order_ids = _args.first[:tracking_order_ids] || _args.first['tracking_order_ids']
    return bulk_call_amazon_tracking_job(tracking_order_ids) if tracking_order_ids.present?

    job_status_id = _args.last[:job_status_id] || _args.last['job_status_id']
    job_status = JobStatus.find_by(id: job_status_id)
    return unless job_status.present?

    return if job_status.status_busy?

    arguments = job_status.arguments.nil? ? {} : job_status.arguments
    queue = job_status.name.constantize.set(wait: job_status.perform_in.seconds).perform_later(arguments.merge(job_status_id: job_status_id))
    job_status.update( job_id: queue.job_id)
  end

  def bulk_call_amazon_tracking_job(ids)
    job_statuses = JobStatus.where(id: ids)
    job_statuses.each do |job|
    next if job.status_busy?

    arguments = job.arguments.nil? ? {} : job.arguments
    queue = job.name.constantize.set(wait: job.perform_in.seconds).perform_later(arguments.merge(job_status_id: job.id))
    job.update( job_id: queue.job_id)
    end
  end

end
