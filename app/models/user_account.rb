class UserAccount < ApplicationRecord
  belongs_to :user
  belongs_to :account

  validates_presence_of :user
  validates_presence_of :account

  after_save :touch_account_lifespan
  after_destroy :touch_account_lifespan
end
