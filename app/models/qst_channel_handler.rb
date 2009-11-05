class QstChannelHandler < ChannelHandler
  def handle(msg)
    outgoing = QSTOutgoingMessage.new
    outgoing.channel_id = @channel.id
    outgoing.guid = msg.guid
    outgoing.save
  end
  
  def authenticate(password)
    @channel.configuration[:password] == Digest::SHA2.hexdigest(@channel.configuration[:salt] + password)
  end
  
  def check_valid
    @channel.errors.add(:password, "can't be blank") if
        @channel.configuration[:password].nil? || @channel.configuration[:password].chomp.empty?
        
    @channel.errors.add(:password, "doesn't match confirmation") if
        !@channel.configuration[:password].nil? && !@channel.configuration[:password_confirmation].nil? && @channel.configuration[:password] != @channel.configuration[:password_confirmation]
  end
  
  def update(params)
    @channel.protocol = params[:protocol]
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