class ATMessage < ActiveRecord::Base
  belongs_to :account
  belongs_to :application
  belongs_to :channel
  validates_presence_of :account
  serialize :custom_attributes, Hash

  include MessageCommon
  include MessageGetter
  include MessageState
  
   # Logs that each message was delivered/not delivered through the given interface
  def self.log_delivery(msgs, account, interface)
    msgs.each do |msg|
      if msg.tries < account.max_tries
        account.logger.at_message_delivery_succeeded msg, interface
      else
        account.logger.at_message_delivery_exceeded_tries msg, interface
      end
    end
  end
  
end
