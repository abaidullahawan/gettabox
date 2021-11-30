class MailServiceRule < ApplicationRecord
  belongs_to :channel_order
  has_many :mail_service_labels
  accepts_nested_attributes_for :mail_service_labels

end
