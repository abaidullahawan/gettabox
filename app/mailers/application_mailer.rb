# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base # :nodoc:
  default from: 'munchionclick@gmail.com'
  layout 'mailer'
end
