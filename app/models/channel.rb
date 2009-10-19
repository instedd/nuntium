class Channel < ActiveRecord::Base
  belongs_to :application
  has_many :qst_outgoing_messages
  serialize :configuration
end
