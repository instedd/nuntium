class QstOutgoingMessage < ActiveRecord::Base
  belongs_to :ao_message
  belongs_to :channel
  validates_presence_of :channel

  include MessageGetter

  def guid
    self.ao_message.try :guid
  end
end
