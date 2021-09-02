class User < ApplicationRecord
  acts_as_paranoid
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_one_attached :profile_image
  has_one :personal_detail, as: :bio
  has_one_attached :avatar
  accepts_nested_attributes_for :personal_detail

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: {
    super_admin: 0,
    admin: 1,
    staff: 2
  }, _prefix: true

  validates :role, presence: true
  validates :email, format: { with: Devise.email_regexp }

  attr_accessor :limit
  def self.filter_role(current_user)
    if current_user.role_super_admin?
      return ['admin', 'staff']
    else
      return ['staff']
    end
  end

  def self.to_csv
    attributes = all.column_names
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |user|
        csv << attributes.map{ |attr| user.send(attr) }
      end
    end
  end
end
