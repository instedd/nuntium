class MessageController < AccountAuthenticatedController
  include CustomAttributesControllerCommon

  before_filter :check_login

  def new_ao_message
    return redirect_to :controller => :home, :action => :ao_messages if @account.applications.empty?

    @kind = 'ao'
    @selected_tab = :ao_messages
    render "new_message.html.erb"
  end

  def new_at_message
    @kind = 'at'
    @selected_tab = :at_messages
    render "new_message.html.erb"
  end

  def create_ao_message
    msg = create_message AOMessage

    application = @account.applications.find_by_id params[:message][:application_id]
    return redirect_to :controller => :home, :action => :ao_messages unless application

    application.route_ao msg, 'user'

    flash[:notice] = "AO Message was created with id #{msg.id} <a href=\"/message/ao/#{msg.id}\" target=\"_blank\">view log</a> <a href=\"/message/thread?address=#{msg.to}\" target=\"_blank\">view thread</a>"
    redirect_to :controller => :home, :action => :ao_messages
  end

  def create_at_message
    msg = create_message ATMessage
    msg.timestamp = Time.new.utc

    channel = @account.channels.find_by_id params[:message][:channel_id]
    @account.route_at msg, channel

    flash[:notice] = "AT Message was created with id #{msg.id} <a href=\"/message/at/#{msg.id}\" target=\"_blank\">view log</a> <a href=\"/message/thread?address=#{msg.from}\" target=\"_blank\">view thread</a>"
    redirect_to :controller => :home, :action => :at_messages
  end

  def simulate_route_ao
    @msg = create_message AOMessage

    application = @account.applications.find_by_id params[:message][:application_id]
    return redirect_to :controller => :home, :action => :ao_messages unless application

    result = application.route_ao @msg, 'ui', :simulate => true

    @strategy = result[:strategy]
    @channels = result[:channels]
    @channel = result[:channel]
    @messages = result[:messages]
    @log = result[:log]
    @logs = result[:logs]
    @hide_title = true
  end

  def simulate_route_at
    @msg = create_message ATMessage

    channel = @account.channels.find_by_id params[:message][:channel_id]
    @log = @account.route_at @msg, channel, :simulate => true
    @hide_title = true
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
    mark_messages_as_cancelled AOMessage, @account.ao_messages
  end

  def mark_at_messages_as_cancelled
    mark_messages_as_cancelled ATMessage, @account.at_messages
  end

  def mark_messages_as_cancelled(kind, messages)
    all = kind == AOMessage ? :ao_all : :at_all

    if params[all].to_b
      messages = messages.search params[:search] if params[:search].present?
    else
      msgs = kind == AOMessage ? :ao_messages : :at_messages
      messages = messages.where 'id IN (?)', params[msgs]
    end

    affected = messages.all
    affected.each do |msg|
      msg.state = 'cancelled'
      msg.save!
    end

    affected = affected.length

    k = kind == AOMessage ? 'Originated' : 'Terminated'
    flash[:notice] = "#{affected} Application #{k} messages #{affected == 1 ? 'was' : 'were'} marked as cancelled"

    params[:controller] = :home
    params[:action] = "#{kind == AOMessage ? 'ao' : 'at'}_messages"
    redirect_to params
  end

  def reroute_ao_messages
    msgs = @account.ao_messages
    if params[:ao_all].to_b
      msgs = msgs.search params[:search] if params[:search].present?
    else
      msgs = msgs.where 'id IN (?)', params[:ao_messages]
    end

    applications = @account.applications

    msgs.each do |msg|
      application = applications.select{|x| x.id == msg.application_id}.first
      application.reroute_ao msg if application
    end

    flash[:notice] = "#{msgs.length} Application Originated #{msgs.length == 1 ? 'message was' : 'messages were'} re-routed"

    params[:controller] = :home
    params[:action] = :ao_messages
    redirect_to params
  end

  def view_ao_message
    @id = params[:id]
    @msg = AOMessage.find_by_id @id
    return redirect_to :controller => :home, :action => :ao_messages if @msg.nil? || @msg.account_id != @account.id
    @hide_title = true
    @logs = @account.logs.find_all_by_ao_message_id(@id).order(:created_at).all
    @kind = 'ao'
    render "message.html.erb"
  end

  def view_at_message
    @id = params[:id]
    @msg = ATMessage.find_by_id @id
    return redirect_to :controller => :home, :action => :at_messages if @msg.nil? || @msg.account_id != @account.id
    @hide_title = true
    @logs = @account.logs..find_all_by_at_message_id(@id).order(:created_at).all
    @kind = 'at'
    render "message.html.erb"
  end

  def view_thread
    @address = params[:address]
    @page = (params[:page] || '1').to_i
    @hide_title = true

    @applications = @account.applications
    @channels = @account.channels

    limit = @page * 5
    aos = @account.ao_messages.where(:to => @address, :parent_id => nil).order('id DESC').limit(limit)
    ats = @account.at_messages.where(:from => @address).order('id DESC').limit(limit)

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
