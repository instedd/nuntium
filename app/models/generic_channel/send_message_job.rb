# Generic job to send a message via a channel.
# Subclasses must implement managed_perform.
class SendMessageJob

  attr_accessor :application_id, :channel_id, :message_id
  
  def initialize(application_id, channel_id, message_id)
    @application_id = application_id
    @channel_id = channel_id
    @message_id = message_id
  end
  
  def perform
    begin
      @app = Application.find_by_id @application_id
      @channel = Channel.find @channel_id
      @msg = AOMessage.find @message_id
      @config = @channel.configuration
    
      managed_perform
    rescue MessageException => ex
      @msg.send_failed @app, @channel, ex.inner
    end
  end
  
  # Should send the message. If there's a failure, one of these exceptions
  # should be thrown:
  #  - MessageException: intrinsic to the message
  #  - TemporaryException: like "we don't have an internet connection"
  #  - PermanentException: like "the password is wrong"
  def managed_perform
    raise PermanentException.new(Exception.new("managed_perform method is not implemented for #{self.class.name}")) 
  end

end
