class QstChannelHandler < ChannelHandler
  def handle(msg)
    outgoing = QSTOutgoingMessage.new
    outgoing.channel_id = @channel.id
    outgoing.ao_message_id = msg.id
    outgoing.save
  end
  
  def authenticate(password)
    @channel.configuration[:password] == Digest::SHA2.hexdigest(@channel.configuration[:salt] + password)
  end
  
  def check_valid
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
    
    if !@channel.configuration[:password].nil? && !@channel.configuration[:password_confirmation].nil? && @channel.configuration[:password] != @channel.configuration[:password_confirmation]
      if !@channel.configuration[:password].nil?
        @channel.configuration[:password_confirmation] = Digest::SHA2.hexdigest(@channel.configuration[:salt] + @channel.configuration[:password_confirmation])
        if !@channel.configuration[:password].nil? && !@channel.configuration[:password_confirmation].nil? && @channel.configuration[:password] != @channel.configuration[:password_confirmation]
          @channel.errors.add(:password, "doesn't match confirmation")
        end
      else
        @channel.errors.add(:password, "doesn't match confirmation")
      end
    end  
  end
  
  def update(params)
    @channel.protocol = params[:protocol]
    @channel.direction = params[:direction]
    
    if !params[:configuration][:password].chomp.empty?
      @channel.configuration[:salt] = nil
      @channel.configuration[:password] = params[:configuration][:password]
      @channel.configuration[:password_confirmation] = params[:configuration][:password_confirmation]
    else
      @channel.configuration[:password_confirmation] = @channel.configuration[:password]
    end
  end
  
  def before_save
    if !@channel.configuration[:salt].nil?
      return
    end
    
    @channel.configuration[:salt] = ActiveSupport::SecureRandom.base64(8)
    @channel.configuration[:password] = Digest::SHA2.hexdigest(@channel.configuration[:salt] + @channel.configuration[:password])
  end
  
  def clear_password
    @channel.configuration[:salt] = nil
    @channel.configuration[:password] = nil
  end
end