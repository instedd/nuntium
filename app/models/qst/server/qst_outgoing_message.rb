class QSTOutgoingMessage < ActiveRecord::Base
  belongs_to :channel
  validates_presence_of :channel
end