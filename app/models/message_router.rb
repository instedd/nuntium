class MessageRouter 

  attr_reader :msg

  def initialize(application, msg, channels, preferred_channel, via_interface, logger)
    @account = application.account
    @application = application
    @msg = msg
    @channels = channels
    @preferred_channel = preferred_channel
    @via_interface = via_interface
    @logger = logger
  end
  
  def route_to_any_channel
    if !@preferred_channel.nil?
      channels = @channels.select{|x| x.name == @preferred_channel}
    else
      channels = @channels
    end
    
    if channels.empty?
      @msg.state = 'error'
      @msg.save!
      
      @logger.ao_message_received @msg, @via_interface
      @logger.no_channel_found_for_ao_message @msg.to.protocol, @msg
      return
    end
    
    # Select channels with less or equal metric than the other channels
    channels = channels.select{|c| channels.all?{|x| c.metric <= x.metric }}
    
    # Select a random channel to handle the message
    channel = channels[rand(channels.length)]

    push_message_into channel
  end
  
  def push_message_into(channel)
    # Save the message
    @msg.channel = channel
    @msg.state = 'queued'
    @msg.save!
    
    # Do some logging
    @logger.ao_message_received @msg, @via_interface
    @logger.ao_message_handled_by_channel @msg, channel
    
    # Let the channel handle the message
    channel.handle @msg
  end
end
