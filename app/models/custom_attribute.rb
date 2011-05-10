class CustomAttribute < ActiveRecord::Base
  belongs_to :account
  serialize :custom_attributes, Hash
  validates_presence_of :address
  validates_uniqueness_of :address, :scope => :account_id
end
