class ChannelController < AuthenticatedController

  before_filter :check_login
  
  def new_channel
    @channel = flash[:channel]
    
    kind = params[:kind]
    render "new_#{kind}_channel.html.erb"
  end
  
  def create_channel
    chan = params[:channel]
    
    if chan.nil?
      redirect_to_home
      return
    end
    
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
    @channel = Channel.find params[:id]
    if @channel.nil? || @channel.application_id != @application.id
      redirect_to_home
      return
    end
    
    if !flash[:channel].nil?
      @channel = flash[:channel]
    end
    
    render "edit_#{@channel.kind}_channel.html.erb"
  end
  
  def update_channel
    chan = params[:channel]
    
    if chan.nil?
      redirect_to_home
      return
    end
    
    @channel = Channel.find params[:id]
    if @channel.nil? || @channel.application_id != @application.id
      redirect_to_home
      return
    end
    
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
    @channel = Channel.find params[:id]
    if @channel.nil? || @channel.application_id != @application.id
      redirect_to_home
      return
    end
    
    @channel.delete
    
    flash[:notice] = 'Channel was deleted'
    redirect_to_home
  end

end