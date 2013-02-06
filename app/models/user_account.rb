class UserAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :account

  validates_presence_of :user
  validates_presence_of :account
end
