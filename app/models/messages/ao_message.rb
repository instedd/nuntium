require 'drb'

class AOMessage < ActiveRecord::Base
  # need to include this to share an AOMessage across different DRb services
  include DRbUndumped
  
  belongs_to :application
  belongs_to :channel
  validates_presence_of :application
  
  include MessageCommon
  include MessageGetter
  include MessageState

end