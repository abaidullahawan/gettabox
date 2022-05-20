# frozen_string_literal: true

# Job Status
class JobStatus < ApplicationRecord

  def self.sec_to_hours(sec)
    "%02d:%02d:%02d" % [sec / 3600, sec / 60 % 60, sec % 60]
  end
end
