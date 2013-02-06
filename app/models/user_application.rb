class UserApplication < ActiveRecord::Base
  belongs_to :user
  belongs_to :application

  validates_presence_of :user
  validates_presence_of :application
end
