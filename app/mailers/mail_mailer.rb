# frozen_string_literal: true

# mail for purhcase order reminder
class MailMailer < ApplicationMailer
  # default: 'email.from.devbox@gmail.com'
  def send_email(pdf, subject, email, name, body)
    @supplier_name = name
    @body = body
    @subject = subject
    pdf.each_with_index do |pdf_s, _index|
      attachments["#{pdf_s.last}.pdf"] = pdf_s.first
    end
    mail(to: email, subject: "#{subject} ")
  end

  def new_email
    mail(to: params[:to],
         subject: params[:subject],
         cc: params[:cc],
         body: params[:message])
  end
end
