require 'twitter'

class TwitterController < AuthenticatedController

  def create_twitter_channel
    chan = params[:channel]
    
    if chan.nil?
      redirect_to_home
      return
    end
    
    @channel = Channel.new(chan)
    if @channel.name.blank?
      @channel.errors.add(:name, "can't be blank")
      flash[:channel] = @channel
      redirect_to :controller => :home, :action => :new_channel
      return
    end
    
    oauth = TwitterChannelHandler.new_oauth
    
    request_token = oauth.request_token
  
    session['twitter_token'] = request_token.token
    session['twitter_secret'] = request_token.secret
    session['twitter_channel_name'] = @channel.name
    session['twitter_channel_welcome_message'] = @channel.configuration[:welcome_message]
    
    redirect_to request_token.authorize_url
  end
  
  def update_twitter_channel
    oauth = TwitterChannelHandler.new_oauth
    
    request_token = oauth.request_token
    
    session['twitter_token'] = request_token.token
    session['twitter_secret'] = request_token.secret
    session['twitter_channel_id'] = params[:id]
    session['twitter_channel_welcome_message'] = params[:channel][:configuration][:welcome_message]
    
    redirect_to request_token.authorize_url
  end
  
  def twitter_callback
    oauth = TwitterChannelHandler.new_oauth
    oauth.authorize_from_request(session['twitter_token'], session['twitter_secret'], params[:oauth_verifier])
    profile = Twitter::Base.new(oauth).verify_credentials
    access_token = oauth.access_token
    
    if session['twitter_channel_id'].nil?
      @update = false
      @channel = Channel.new
      @channel.application_id = @application.id
      @channel.name = session['twitter_channel_name']      
      @channel.kind = 'twitter'
      @channel.protocol = 'twitter'
      @channel.direction = Channel::Both  
    else
      @update = true
      @channel = Channel.find session['twitter_channel_id']
    end
    
    @channel.configuration = {
      :welcome_message => session['twitter_channel_welcome_message'],
      :screen_name => profile.screen_name,
      :token => access_token.token,
      :secret => access_token.secret
      }
    
    session['twitter_token']  = nil
    session['twitter_secret'] = nil
    session['twitter_channel_id'] = nil
    session['twitter_channel_name'] = nil
    session['twitter_channel_welcome_message'] = nil    

    if @channel.save
      flash[:notice] = @update ? 'Channel was updated' : 'Channel was created'
    else
      flash[:notice] = "Channel couldn't be saved"
    end
    redirect_to_home
  end

end