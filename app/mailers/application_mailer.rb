# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base # :nodoc:
  default from: 'email.from.devbox@gmail.com'
  layout 'mailer'
end
