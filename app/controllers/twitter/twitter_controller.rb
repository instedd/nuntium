require 'twitter'

class TwitterController < AccountAuthenticatedController

  include CustomAttributesControllerCommon

  before_filter :check_login
  before_filter :check_twitter_properly_configured

  def create_twitter_channel
    chan = params[:channel]
    return redirect_to_home if chan.nil?
    
    @channel = Channel.new(chan)
    
    if @channel.name.blank?
      @channel.errors.add(:name, "can't be blank")
      return render "channel/new_twitter_channel"
    end
    
    oauth = TwitterChannelHandler.new_oauth
    
    request_token = oauth.request_token
  
    session['twitter_token'] = request_token.token
    session['twitter_secret'] = request_token.secret
    session['twitter_channel_name'] = @channel.name
    session['twitter_channel_priority'] = @channel.priority
    session['twitter_channel_application_id'] = @channel.application_id
    session['twitter_channel_welcome_message'] = @channel.configuration[:welcome_message]
    session['twitter_channel_custom_attributes'] = get_custom_attributes
    
    redirect_to request_token.authorize_url
  end
  
  def update_twitter_channel
    oauth = TwitterChannelHandler.new_oauth
    
    request_token = oauth.request_token
    
    session['twitter_token'] = request_token.token
    session['twitter_secret'] = request_token.secret
    session['twitter_channel_id'] = params[:id]
    session['twitter_channel_priority'] = params[:channel][:priority]
    session['twitter_channel_application_id'] = params[:channel][:application_id]
    session['twitter_channel_welcome_message'] = params[:channel][:configuration][:welcome_message]
    session['twitter_channel_custom_attributes'] = get_custom_attributes
    
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
      @channel.account_id = @account.id
      @channel.name = session['twitter_channel_name']      
      @channel.kind = 'twitter'
      @channel.protocol = 'twitter'
      @channel.direction = Channel::Bidirectional
    else
      @update = true
      @channel = @account.find_channel session['twitter_channel_id']
    end
    
    @channel.configuration = {
      :welcome_message => session['twitter_channel_welcome_message'],
      :screen_name => profile.screen_name,
      :token => access_token.token,
      :secret => access_token.secret
      }
    @channel.priority = session['twitter_channel_priority']
    @channel.application_id = session['twitter_channel_application_id']
    @channel.restrictions = session['twitter_channel_custom_attributes']
    
    session['twitter_token']  = nil
    session['twitter_secret'] = nil
    session['twitter_channel_id'] = nil
    session['twitter_channel_name'] = nil
    session['twitter_channel_priority'] = nil
    session['twitter_channel_application_id'] = nil
    session['twitter_channel_welcome_message'] = nil
    session['twitter_channel_custom_attributes'] = nil

    if @channel.save
      flash[:notice] = @update ? 'Channel was updated' : 'Channel was created'
    else
      flash[:notice] = "Channel couldn't be saved"
    end
    redirect_to_home
  end
  
  def view_rate_limit_status
    id = params[:id]
    @channel = @account.find_channel id
    if @channel.nil? || @channel.account_id != @account.id || @channel.kind != 'twitter'
      return redirect_to_home
    end
    
    render :text => @channel.handler.get_rate_limit_status
  end
  
  protected
  
  def check_twitter_properly_configured
    return redirect_to_home if TwitterConsumerConfig.nil?
  end

end
