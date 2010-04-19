class AOMessage < ActiveRecord::Base  
  belongs_to :application
  belongs_to :channel
  validates_presence_of :application
  
  include MessageCommon
  include MessageGetter
  include MessageState
  
  def send_succeeed(app, channel, channel_relative_id = nil)
    self.state = 'delivered'
    self.tries += 1
    self.channel_relative_id = channel_relative_id unless channel_relative_id.nil?
    self.save!
    
    app.logger.message_channeled self, channel
  end
  
  def send_failed(app, channel, exception)
    self.tries += 1
    if self.tries >= app.max_tries
      self.state = 'failed'
    end
    self.save!
    
    app.logger.exception_in_channel_and_ao_message channel, self, exception
  end

end
