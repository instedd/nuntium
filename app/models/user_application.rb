class UserApplication < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :application

  validates_presence_of :user
  validates_presence_of :application

  after_save :touch_application_lifespan
  after_destroy :touch_application_lifespan
  after_save :touch_account_lifespan
  after_destroy :touch_account_lifespan
end
