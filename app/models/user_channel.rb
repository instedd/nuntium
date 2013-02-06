class UserChannel < ActiveRecord::Base
  belongs_to :user
  belongs_to :channel

  validates_presence_of :user
  validates_presence_of :channel
end
