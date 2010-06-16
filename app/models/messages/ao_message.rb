class AOMessage < ActiveRecord::Base  
  belongs_to :account
  belongs_to :application
  belongs_to :channel
  validates_presence_of :account
  serialize :custom_attributes, Hash
  
  after_save :send_delivery_ack
  
  include MessageCommon
  include MessageGetter
  include MessageState
  
  def send_succeeed(account, channel, channel_relative_id = nil)
    self.state = 'delivered'
    self.tries += 1
    self.channel_relative_id = channel_relative_id unless channel_relative_id.nil?
    self.save!
    
    account.logger.message_channeled self, channel
  end
  
  def send_failed(account, channel, exception)
    self.tries += 1
    if self.tries >= account.max_tries
      self.state = 'failed'
    end
    self.save!
    
    account.logger.exception_in_channel_and_ao_message channel, self, exception
  end
  
  private
  
  def send_delivery_ack
    return true unless state == 'failed' || state == 'delivered' || state == 'confirmed'
    return true unless channel_id
    
    app = self.application
    return true unless app and app.delivery_ack_method != 'none'
    
    Queues.publish_application app, SendDeliveryAckJob.new(account_id, application_id, id, state) 
    true
  end

end
