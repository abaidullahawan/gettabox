class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
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


  def self.filter_role(current_user)
    if current_user.role_super_admin?
      return ['admin', 'staff']
    else
      return ['staff']
    end
  end
end
