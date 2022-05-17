# frozen_string_literal: true

module ElapsedTimeHelper # :nodoc:

  def elapsed_time(authorization)
    credential = Credential.find_by(grant_type: 'wait_time')
    wait_time = credential.created_at
    wait_time = DateTime.now > wait_time ? DateTime.now + 130.seconds : wait_time + 130.seconds
    credential.update(redirect_uri: 'AmazonTrackingJob', authorization: authorization, created_at: wait_time)
    wait_time - DateTime.now
  end

end
