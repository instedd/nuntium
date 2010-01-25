class ATMessage < ActiveRecord::Base
  belongs_to :application
  belongs_to :channel
  validates_presence_of :application

  include MessageCommon
  include MessageGetter
  include MessageState
  
   # Logs that each message was delivered/not delivered through the given interface
  def self.log_delivery(msgs, application, interface)
    msgs.each do |msg|
      if msg.tries < application.max_tries
        application.logger.at_message_delivery_succeeded msg, interface
      else
        application.logger.at_message_delivery_exceeded_tries msg, interface
      end
    end
  end
  
end
