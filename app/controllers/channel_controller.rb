class ChannelController < AuthenticatedController

  include ChannelControllerCommon

  before_filter :check_login
  before_filter :check_channel, :except => [:new_channel, :create_channel]
  after_filter :compress, :only => [:new_channel, :edit_channel]
  
  def new_channel
    @channel = Channel.new :configuration => {} unless @channel
    kind = params[:kind]
    render "new_#{kind}_channel"
  end
  
  def create_channel
    chan = params[:channel]
    return redirect_to_home if chan.nil?
    
    throttle_opt = chan.delete :throttle_opt
    
    @channel = Channel.new(chan)
    @channel.account_id = @account.id
    @channel.kind = params[:kind]
    @channel.direction = chan[:direction]
    @channel.throttle = throttle_opt == 'on' ? chan[:throttle].to_i : nil
    @channel.custom_attributes = get_custom_attributes
    
    @channel.check_valid_in_ui
    if !@channel.save
      @channel.clear_password
      return render "new_#{@channel.kind}_channel"
    end
    
    redirect_to_home 'Channel was created'
  end
  
  def edit_channel
    if File.exists? "#{view_paths}/channel/edit_#{@channel.kind}_channel.html.erb"
      render "edit_#{@channel.kind}_channel"
    else
      render "new_#{@channel.kind}_channel"
    end
  end
  
  def update_channel
    chan = params[:channel]
    return redirect_to_home if chan.nil?
    
    throttle_opt = chan.delete :throttle_opt
    
    @channel.handler.update(chan)
    @channel.throttle = throttle_opt == 'on' ? chan[:throttle].to_i : nil
    @channel.custom_attributes = get_custom_attributes
    
    @channel.check_valid_in_ui
    if !@channel.save
      @channel.clear_password
      return edit_channel
    end
    
    redirect_to_home 'Channel was updated'
  end
  
  def delete_channel
    @channel.destroy
    
    redirect_to_home 'Channel was deleted'
  end
  
  def enable_channel
    @channel.enabled = true
    @channel.save!
    
    redirect_to_home 'Channel was enabled'
  end
  
  def disable_channel
    @channel.enabled = false
    @channel.save!
    
    # If other channels for the same protocol exist, re-queue
    # queued messages in those channels.
    requeued_messages_count = 0;
    
    other_channels = @account.channels.all(:conditions => ['enabled = ? AND protocol = ? AND (direction = ? OR direction = ?)', true, @channel.protocol, Channel::Outgoing, Channel::Bidirectional])
    
    if !other_channels.empty?
      queued_messages = AOMessage.all(:conditions => ['channel_id = ? AND state = ?', @channel.id, 'queued'])
      requeued_messages_count = queued_messages.length
      queued_messages.each do |msg|
        @account.route(msg, 'user')
      end
    end
    
    if requeued_messages_count == 0
      flash[:notice] = 'Channel was disabled'
    elsif requeued_messages_count == 1
      flash[:notice] = 'Channel was disabled and 1 message was re-queued'
    else
      flash[:notice] = "Channel was disabled and #{requeued_messages_count} messages were re-queued"
    end
    redirect_to_home
  end
  
  protected
  
  def check_channel
    @channel = Channel.find_by_id params[:id]
    redirect_to_home if @channel.nil? || @channel.account_id != @account.id
  end

end
