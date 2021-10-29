# frozen_string_literal: true

# mail for purhcase order reminder
class PurchaseOrderMailer < ApplicationMailer
  def send_email(pdf, subject, email, name, body)
    @supplier_name = name
    @body = body
    @subject = subject
    pdf.each_with_index do |pdf_s, _index|
      attachments["#{pdf_s.last}.pdf"] = pdf_s.first
    end
    mail(to: email, subject: "#{subject} ")
  end
end
