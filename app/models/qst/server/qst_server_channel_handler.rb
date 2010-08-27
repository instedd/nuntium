require 'digest/sha1'

class QstServerChannelHandler < ChannelHandler
  def handle(msg)
    outgoing = QSTOutgoingMessage.new
    outgoing.channel_id = @channel.id
    outgoing.ao_message_id = msg.id
    outgoing.save
  end
  
  def authenticate(password)
    @channel.configuration[:password] == hash(decoded_salt, password)
  end
  
  def check_valid
    config = @channel.configuration
    pass = config[:password]
    confirm = config[:password_confirmation]
    salt = config[:salt]
  
    @channel.errors.add(:password, "can't be blank") if pass.blank?
    
    if pass && confirm && pass != confirm
      if pass and salt
        confirm = hash salt, confirm
        if pass && confirm && pass != confirm
          @channel.errors.add(:password, "doesn't match confirmation")
        end
      else
        @channel.errors.add(:password, "doesnBase64.encode64(Digest::SHA1.digest(salt + Iconv.conv('ucs-2le', 'utf-8', confirm)))'t match confirmation")
      end
    end
    
    config.delete :password_confirmation
  end
  
  def update(params)
    @channel.protocol = params[:protocol]
    @channel.direction = params[:direction]
    @channel.priority = params[:priority]
    @channel.address = params[:address]
    @channel.application_id = params[:application_id]
    
    if !params[:configuration][:password].blank?
      @channel.configuration[:salt] = nil
      @channel.configuration[:password] = params[:configuration][:password]
      @channel.configuration[:password_confirmation] = params[:configuration][:password_confirmation]
    else
      @channel.configuration[:password_confirmation] = @channel.configuration[:password]
    end
  end
  
  def before_save
    return if !@channel.configuration[:salt].nil?
    @channel.configuration[:salt] = ActiveSupport::SecureRandom.base64(8)
    @channel.configuration[:password] = hash decoded_salt, @channel.configuration[:password]
  end
  
  def clear_password
    @channel.configuration[:salt] = nil
    @channel.configuration[:password] = nil
  end
  
  def decoded_salt
    Base64.decode64 @channel.configuration[:salt]
  end
  
  def hash(salt, password)
    Base64.encode64(Digest::SHA1.digest(salt + Iconv.conv('ucs-2le', 'utf-8', password))).strip
  end
end
