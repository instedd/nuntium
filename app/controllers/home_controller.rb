require 'will_paginate'

class HomeController < ApplicationController

  before_filter :check_login, :except => [:index, :login, :create_application]

  def index
    if !session[:application].nil?
      redirect_to :home
      return
    end
  
    @application = flash[:application]
    @new_application = flash[:new_application]
  end
  
  def login
    app = params[:application]
    
    if app.nil?
      redirect_to :action => :home
      return
    end
    
    @application = Application.find_by_name app[:name]
    if @application.nil? || !@application.authenticate(app[:password])
      flash[:application] = Application.new(:name => app[:name])
      flash[:notice] = 'Invalid name/password'
      redirect_to :action => :index
      return
    end
    
    @application.clear_password
    
    session[:application] = @application
    redirect_to :action => :home
  end
  
  def create_application
    app = params[:new_application]
    
    if app.nil?
      redirect_to :action => :home
      return
    end
    
    new_app = Application.new(app)
    if !new_app.save
      new_app.clear_password
      flash[:new_application] = new_app
      redirect_to :action => :index
      return
    end
    
    new_app.clear_password
    
    session[:application] = new_app
    redirect_to :action => :home
  end
  
  def home
    @results_per_page = 10
    
    build_ao_messages_filter
    
    @ao_messages = AOMessage.paginate(
      :conditions => @ao_conditions,
      :order => 'timestamp DESC',
      :page => @ao_page,
      :per_page => @results_per_page
      )
    
    build_at_messages_filter
      
    @at_messages = ATMessage.paginate(
      :conditions => @at_conditions,
      :order => 'timestamp DESC',
      :page => @at_page,
      :per_page => @results_per_page
      )
      
    @logs = ApplicationLog.paginate(
      :conditions => ['application_id = ?', @application.id],
      :include => :channel,
      :order => 'id DESC',
      :page => params[:logs_page],
      :per_page => @results_per_page
      )
      
    @channels = @application.channels.all
  end
  
  def build_ao_messages_filter
    @ao_page = params[:ao_page]
    @ao_page = 1 if @ao_page.blank?    
    @ao_search = params[:ao_search]
    @ao_previous_search = params[:ao_previous_search]
    # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
    @ao_page = 1 if !@ao_previous_search.blank? and @ao_previous_search != @ao_search
    @ao_conditions = build_message_filter(@ao_search)
  end
  
  def build_at_messages_filter
    @at_page = params[:at_page]
    @at_page = 1 if @at_page.blank?    
    @at_search = params[:at_search]
    @at_previous_search = params[:at_previous_search]
    # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
    @at_page = 1 if !@at_previous_search.blank? and @at_previous_search != @at_search
    @at_conditions = build_message_filter(@at_search)
  end
  
  def build_message_filter(search)
    search = Search.new(search)
    conds = ['application_id = :application_id', { :application_id => @application.id }]
    if !search.search.nil?
      conds[0] += ' AND (guid = :search OR [from] LIKE :search OR [to] LIKE :search OR subject LIKE :search OR body LIKE :search)'
      conds[1][:search] = '%' + search.search + '%'
    end
    
    [:id, :guid, :tries].each do |sym|
      if !search[sym].nil?
        conds[0] += " AND [#{sym}] = :#{sym}"
        conds[1][sym] = search[sym]
      end
    end
    [:from, :to, :subject, :body, :state].each do |sym|
      if !search[sym].nil?
        conds[0] += " AND [#{sym}] LIKE :#{sym}"
        conds[1][sym] = '%' + search[sym] + '%'
      end
    end
    if !search[:after].nil?
      begin
        after = Time.parse(search[:after])
        conds[0] += ' AND timestamp >= :after'
        conds[1][:after] = search[:after]
      rescue
      end
    end
    if !search[:before].nil?
      begin
        before = Time.parse(search[:before])
        conds[0] += ' AND timestamp <= :before'
        conds[1][:before] = search[:before]
      rescue
      end
    end
    conds
  end
  
  def edit_application
    if !flash[:application].nil?
      @application = flash[:application]
    end
  end
  
  def update_application
    app = params[:application]
    
    if app.nil?
      redirect_to :action => :home
      return
    end
    
    existing_app = Application.find @application.id
    existing_app.max_tries = app[:max_tries]
    
    if !app[:password].chomp.empty?
      existing_app.salt = nil
      existing_app.password = app[:password]
      existing_app.password_confirmation = app[:password_confirmation]
    end
    
    if !existing_app.save
      existing_app.clear_password
      flash[:application] = existing_app
      redirect_to :action => :edit_application
      return
    end
    
    existing_app.clear_password
    
    flash[:notice] = 'Application was changed'
    session[:application] = existing_app
    redirect_to :action => :home
  end
  
  def new_channel
    @channel = flash[:channel]
    
    kind = params[:kind]
    render "new_#{kind}_channel.html.erb"
  end
  
  def create_channel
    chan = params[:channel]
    
    if chan.nil?
      redirect_to :action => :home
      return
    end
    
    @channel = Channel.new(chan)
    @channel.application_id = @application.id
    @channel.kind = params[:kind]
    @channel.direction = params[:direction]
    
    @channel.check_valid_in_ui
    if !@channel.save
      @channel.clear_password
      flash[:channel] = @channel
      redirect_to :action => :new_channel
      return
    end
    
    flash[:notice] = 'Channel was created'
    redirect_to :action => :home
  end
  
  def create_twitter_channel
    chan = params[:channel]
    
    if chan.nil?
      redirect_to :action => :home
      return
    end
    
    @channel = Channel.new(chan)
    if @channel.name.blank?
      @channel.errors.add(:name, "can't be blank")
      flash[:channel] = @channel
      redirect_to :action => :new_channel
      return
    end
    
    require 'twitter'
    
    oauth = TwitterChannelHandler.new_oauth
    
    request_token = oauth.request_token
  
    session['twitter_token'] = request_token.token
    session['twitter_secret'] = request_token.secret
    session['twitter_channel_name'] = @channel.name
    session['twitter_channel_welcome_message'] = @channel.configuration[:welcome_message]
    
    redirect_to request_token.authorize_url
  end
  
  def update_twitter_channel
    require 'twitter'
    
    oauth = TwitterChannelHandler.new_oauth
    
    request_token = oauth.request_token
    
    session['twitter_token'] = request_token.token
    session['twitter_secret'] = request_token.secret
    session['twitter_channel_id'] = params[:id]
    session['twitter_channel_welcome_message'] = params[:channel][:configuration][:welcome_message]
    
    redirect_to request_token.authorize_url
  end
  
  def twitter_callback
    require 'twitter'
    
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
    redirect_to :action => :home
  end
  
  def edit_channel
    @channel = Channel.find params[:id]
    if @channel.nil? || @channel.application_id != @application.id
      redirect_to :action => :home
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
      redirect_to :action => :home
      return
    end
    
    @channel = Channel.find params[:id]
    if @channel.nil? || @channel.application_id != @application.id
      redirect_to :action => :home
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
    redirect_to :action => :home
  end
  
  def delete_channel
    @channel = Channel.find params[:id]
    if @channel.nil? || @channel.application_id != @application.id
      redirect_to :action => :home
      return
    end
    
    @channel.delete
    
    flash[:notice] = 'Channel was deleted'
    redirect_to :action => :home
  end
  
  def mark_ao_messages_as_cancelled
    if !params[:ao_all].nil? && params[:ao_all] == '1'
      build_ao_messages_filter
      
      AOMessage.update_all("state = 'cancelled'", @ao_conditions)
      affected = AOMessage.count(:conditions => @ao_conditions)
    else
      ids = params[:ao_messages]
      
      AOMessage.update_all("state = 'cancelled'", ['id IN (?)', ids])
      
      affected = ids.length
    end

    flash[:notice] = "#{affected} Application Oriented messages #{affected == 1 ? 'was' : 'were'} marked as cancelled"    
    params[:action] = :home
    redirect_to params
  end
  
  def mark_at_messages_as_cancelled
    if !params[:at_all].nil? && params[:at_all] == '1'
      build_at_messages_filter
      
      ATMessage.update_all("state = 'cancelled'", @at_conditions)
      affected = ATMessage.count(:conditions => @at_conditions)
    else
      ids = params[:at_messages]
      
      ATMessage.update_all("state = 'cancelled'", ['id IN (?)', ids])
      
      affected = ids.length
    end

    flash[:notice] = "#{affected} Application Terminated messages #{affected == 1 ? 'was' : 'were'} marked as cancelled"    
    params[:action] = :home
    redirect_to params
  end
  
  def logoff
    session[:application] = nil
    redirect_to :action => :index
  end
  
  def check_login
    if session[:application].nil?
      redirect_to :action => :index
      return
    end
    
    @application = session[:application]
  end

end