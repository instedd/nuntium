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
    
    redirect_to_home "AO Message was created with id #{msg.id} <a href=\"/message/ao/#{msg.id}\" target=\"_blank\">view log</a> <a href=\"/message/thread?address=#{msg.to}\" target=\"_blank\">view thread</a>"
  end
  
  def create_at_message
    msg = create_message ATMessage
    msg.timestamp = Time.new.utc
    
    channel = @account.find_channel params[:message][:channel_id]
    @account.route_at msg, channel
    
    redirect_to_home "AT Message was created with id #{msg.id} <a href=\"/message/at/#{msg.id}\" target=\"_blank\">view log</a> <a href=\"/message/thread?address=#{msg.from}\" target=\"_blank\">view thread</a>"
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
    params[:action] = :index
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
    
    flash[:notice] = "#{msgs.length} Application Originated #{msgs.length == 1 ? 'message was' : 'messages were'} re-routed"
    
    params[:controller] = :home
    params[:action] = :index
    redirect_to params
  end
  
  def view_ao_message
    @id = params[:id]
    @msg = AOMessage.find_by_id @id
    return redirect_to_home if @msg.nil? || @msg.account_id != @account.id
    @hide_title = true
    @logs = AccountLog.find_all_by_account_id_and_ao_message_id(@account.id, @id, :order => :created_at)
    @kind = 'ao'
    render "message.html.erb"
  end
  
  def view_at_message
    @id = params[:id]
    @msg = ATMessage.find_by_id @id
    return redirect_to_home if @msg.nil? || @msg.account_id != @account.id
    @hide_title = true
    @logs = AccountLog.find_all_by_account_id_and_at_message_id(@account.id, @id, :order => :created_at)
    @kind = 'at'
    render "message.html.erb"
  end
  
  def view_thread
    def esc(name)
      ActiveRecord::Base.connection.quote_column_name(name)
    end
  
    @address = params[:address]
    @page = (params[:page] || '1').to_i
    @hide_title = true
    
    @applications = @account.applications
    @channels = @account.channels
    
    limit = @page * 5
    aos = AOMessage.all :conditions => ["account_id = ? AND #{esc('to')} = ? AND parent_id IS NULL", @account.id, @address], :order => 'id DESC', :limit => limit 
    ats = ATMessage.all :conditions => ["account_id = ? AND #{esc('from')} = ?", @account.id, @address], :order => 'id DESC', :limit => limit
    
    @has_more = aos.length == limit || ats.length == limit
    
    @msgs = []
    aos.each {|x| @msgs << x}
    ats.each {|x| @msgs << x}
    
    @msgs.sort!{|x, y| y.created_at <=> x.created_at}
  end
  
  def ao_rgviz
    render :rgviz => AOMessage, :conditions => ['ao_messages.account_id = ?', @account.id], :extensions => true
  end
  
  def at_rgviz
    render :rgviz => ATMessage, :conditions => ['at_messages.account_id = ?', @account.id], :extensions => true
  end

end
