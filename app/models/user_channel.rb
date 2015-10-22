class UserChannel < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
  belongs_to :channel

  validates_presence_of :user
  validates_presence_of :channel

  after_save :touch_account_lifespan
  after_destroy :touch_account_lifespan
end
