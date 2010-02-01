class MessageController < AuthenticatedController

  include MessageFilters

  before_filter :check_login
  after_filter :compress, :only => [:view_ao_message, :view_at_message]

  def new_ao_message
    @kind = 'ao'
    render "new_message.html.erb"
  end
  
  def new_at_message
    @kind = 'at'
    render "new_message.html.erb"
  end
  
  def create_ao_message
    msg = create_message AOMessage
    
    @application.route msg, 'user'
    
    redirect_to_home 'AO Message was created'
  end
  
  def create_at_message
    msg = create_message ATMessage
    msg.timestamp = Time.new.utc
    @application.accept msg, 'ui'
    
    redirect_to_home 'AT Message was created'
  end
  
  def create_message(kind)
    m = params[:message]
  
    msg = kind.new
    msg.application_id = @application.id
    msg.from = m[:from]
    msg.to = m[:to]
    msg.subject = m[:subject]
    msg.body = m[:body]
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
  
    if !params[all].nil? && params[all] == '1'
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
  
  def view_ao_message
    @id = params[:id]
    @msg = AOMessage.find_by_id @id
    redirect_to_home if @msg.nil? || @msg.application_id != @application.id
    @hide_title = true
    @logs = ApplicationLog.find_all_by_ao_message_id(@id)
    @kind = 'ao'
    render "message.html.erb"
  end
  
  def view_at_message
    @id = params[:id]
    @msg = ATMessage.find_by_id @id
    redirect_to_home if @msg.nil? || @msg.application_id != @application.id
    @hide_title = true
    @logs = ApplicationLog.find_all_by_at_message_id(@id)
    @kind = 'at'
    render "message.html.erb"
  end

end