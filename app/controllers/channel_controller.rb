class ChannelController < AuthenticatedController

  before_filter :check_login
  before_filter :check_channel, :except => [:new_channel, :create_channel]
  
  def new_channel
    @channel = flash[:channel]
    
    kind = params[:kind]
    render "new_#{kind}_channel.html.erb"
  end
  
  def create_channel
    chan = params[:channel]
    return redirect_to_home if chan.nil?
    
    @channel = Channel.new(chan)
    @channel.application_id = @application.id
    @channel.kind = params[:kind]
    @channel.direction = chan[:direction]
    
    @channel.check_valid_in_ui
    if !@channel.save
      @channel.clear_password
      flash[:channel] = @channel
      redirect_to :action => :new_channel
      return
    end
    
    flash[:notice] = 'Channel was created'
    redirect_to_home
  end
  
  def edit_channel
    if !flash[:channel].nil?
      @channel = flash[:channel]
    end
    
    render "edit_#{@channel.kind}_channel.html.erb"
  end
  
  def update_channel
    chan = params[:channel]
    return redirect_to_home if chan.nil?
    
    @channel.handler.update(chan)
    
    @channel.check_valid_in_ui
    if !@channel.save
      @channel.clear_password
      flash[:channel] = @channel
      redirect_to :action => :edit_channel
      return
    end
    
    flash[:notice] = 'Channel was updated'
    redirect_to_home
  end
  
  def delete_channel
    @channel.delete
    
    flash[:notice] = 'Channel was deleted'
    redirect_to_home
  end
  
  def enable_channel
    @channel.enabled = true
    @channel.save!
    
    flash[:notice] = 'Channel was enabled'
    redirect_to_home
  end
  
  def disable_channel
    @channel.enabled = false
    @channel.save!
    
    # If other channels for the same protocol exist, re-queue
    # queued messages in those channels.
    requeued_messages_count = 0;
    
    other_channels = @application.channels.all(:conditions => ['enabled = ? AND protocol = ? AND (direction = ? OR direction = ?)', true, @channel.protocol, Channel::Outgoing, Channel::Both])
    
    if !other_channels.empty?
      queued_messages = AOMessage.all(:conditions => ['channel_id = ? AND state = ?', @channel.id, 'queued'])
      requeued_messages_count = queued_messages.length
      queued_messages.each do |msg|
        @application.route(msg, 'user')
      end
    end
    
    if requeued_messages_count == 0
      flash[:notice] = 'Channel was disabled'
    elsif requeued_messages_count == 1
      flash[:notice] = 'Channel was disabled and 1 message was re-queued'
    else
      flash[:notice] = 'Channel was disabled and ' + requeued_messages_count.to_s + ' messages were re-queued'
    end
    redirect_to_home
  end
  
  protected
  
  def check_channel
    @channel = Channel.find_by_id params[:id]
    if @channel.nil? || @channel.application_id != @application.id
      redirect_to_home
      return
    end
  end

end