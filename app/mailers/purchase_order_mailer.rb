class PurchaseOrderMailer < ApplicationMailer
  def send_email(pdf, subject, email, name)
      @supplier_name = name
      @subject = subject
      pdf.each_with_index do |pdf_s, index|
        attachments["#{pdf_s.last}.pdf"] = pdf_s.first
      end
      mail(to: email, subject: "#{subject} ")
  end
end
