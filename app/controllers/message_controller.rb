class MessageController < AccountAuthenticatedController

  include CustomAttributesControllerCommon
  include MessageFilters

  before_filter :check_login
  after_filter :compress, :only => [:view_ao_message, :view_at_message]

  def new_ao_message
    return redirect_to_home if @account.applications.empty?
  
    @kind = 'ao'
    render "new_message.html.erb"
  end
  
  def new_at_message
    @kind = 'at'
    render "new_message.html.erb"
  end
  
  def create_ao_message
    msg = create_message AOMessage
    
    application = @account.find_application params[:message][:application_id]
    return redirect_to_home unless application
    
    application.route_ao msg, 'user'
    
    redirect_to_home "AO Message was created with id <a href=\"/message/ao/#{msg.id}\" onclick=\"window.open(this.href,'log','width=640,height=480,scrollbars=yes');return false;\">#{msg.id}</a>"
  end
  
  def create_at_message
    msg = create_message ATMessage
    msg.timestamp = Time.new.utc
    
    channel = @account.find_channel params[:message][:channel_id]
    @account.route_at msg, channel
    
    redirect_to_home "AT Message was created with id <a href=\"/message/at/#{msg.id}\" onclick=\"window.open(this.href,'log','width=640,height=480,scrollbars=yes');return false;\">#{msg.id}</a>"
  end
  
  def simulate_route_ao
    @msg = create_message AOMessage
    
    application = @account.find_application params[:message][:application_id]
    return redirect_to_home unless application
    
    result = application.route_ao @msg, 'ui', :simulate => true
    
    @strategy = result[:strategy]
    @channels = result[:channels]
    @channel = result[:channel]
    @messages = result[:messages]
    @log = result[:log]
    @logs = result[:logs]
  end
  
  def simulate_route_at
    @msg = create_message ATMessage
    
    channel = @account.find_channel params[:message][:channel_id]
    @log = @account.route_at @msg, channel, :simulate => true
  end
  
  def create_message(kind)
    m = params[:message]
  
    msg = kind.new
    msg.account_id = @account.id
    msg.from = m[:from]
    msg.to = m[:to]
    msg.subject = m[:subject]
    msg.body = m[:body]
    msg.custom_attributes = get_custom_attributes
    
    return msg
  end
  
  def mark_ao_messages_as_cancelled
    mark_messages_as_cancelled AOMessage
  end
  
  def mark_at_messages_as_cancelled
    mark_messages_as_cancelled ATMessage
  end
  
  def mark_messages_as_cancelled(kind)
    all = kind == AOMessage ? :ao_all : :at_all
  
    if params[all].to_b
      kind == AOMessage ? build_ao_messages_filter : build_at_messages_filter
      conditions = kind == AOMessage ? @ao_conditions : @at_conditions
      kind.update_all("state = 'cancelled'", conditions)
      affected = kind.count(:conditions => conditions)
    else
      msgs = kind == AOMessage ? :ao_messages : :at_messages
      ids = params[msgs]
      
      kind.update_all("state = 'cancelled'", ['id IN (?)', ids])
      
      affected = ids.length
    end
    
    k = kind == AOMessage ? 'Originated' : 'Terminated'
    flash[:notice] = "#{affected} Application #{k} messages #{affected == 1 ? 'was' : 'were'} marked as cancelled"    
    
    params[:controller] = :home
    params[:action] = :home
    redirect_to params
  end
  
  def reroute_ao_messages
    msgs = []
    if params[:ao_all].to_b
      build_ao_messages_filter
      conditions = @ao_conditions
      msgs = AOMessage.all(:conditions => conditions)
    else
      ids = params[:ao_messages]
      msgs = AOMessage.all(:conditions => ['id IN (?)', ids])
    end
    
    applications = @account.applications
    
    msgs.each do |msg|
      application = applications.select{|x| x.id == msg.application_id}.first
      application.reroute_ao msg if application
    end
    
    flash[:notice] = "#{msgs.length} Application Originated messages #{msgs.length == 1 ? 'was' : 'were'} re-routed"
    
    params[:controller] = :home
    params[:action] = :home
    redirect_to params
  end
  
  def view_ao_message
    @id = params[:id]
    @msg = AOMessage.find_by_id @id
    return redirect_to_home if @msg.nil? || @msg.account_id != @account.id
    @hide_title = true
    @logs = AccountLog.find_all_by_ao_message_id(@id, :order => :created_at)
    @kind = 'ao'
    render "message.html.erb"
  end
  
  def view_at_message
    @id = params[:id]
    @msg = ATMessage.find_by_id @id
    return redirect_to_home if @msg.nil? || @msg.account_id != @account.id
    @hide_title = true
    @logs = AccountLog.find_all_by_at_message_id(@id, :order => :created_at)
    @kind = 'at'
    render "message.html.erb"
  end
  
  def view_thread
    def esc(name)
      ActiveRecord::Base.connection.quote_column_name(name)
    end
  
    @address = params[:address]
    @hide_title = true
    
    @applications = @account.applications
    @channels = @account.channels
    
    aos = AOMessage.all :conditions => ["account_id = ? AND #{esc('to')} = ?", @account.id, @address]
    ats = ATMessage.all :conditions => ["account_id = ? AND #{esc('from')} = ?", @account.id, @address]
    
    @msgs = []
    aos.each {|x| @msgs << x}
    ats.each {|x| @msgs << x}    
    @msgs.sort!{|x, y| x.id <=> y.id}
  end

end
