require 'will_paginate'

class HomeController < AuthenticatedController

  include MessageFilters

  before_filter :check_login, :except => [:index, :login, :create_application]

  def index
    if !session[:application_id].nil?
      redirect_to_home
      return
    end
  
    @application = flash[:application]
    @new_application = flash[:new_application]
  end
  
  def login
    app = params[:application]
    
    if app.nil?
      redirect_to_home
      return
    end
    
    @application = Application.find_by_name app[:name]
    if @application.nil? || !@application.authenticate(app[:password])
      flash[:application] = Application.new(:name => app[:name])
      flash[:notice] = 'Invalid name/password'
      redirect_to :action => :index
      return
    end
    
    session[:application_id] = @application.id
    redirect_to_home
  end
  
  def create_application
    app = params[:new_application]
    
    if app.nil?
      redirect_to_home
      return
    end
    
    new_app = Application.new(app)
    if !new_app.save
      new_app.clear_password
      flash[:new_application] = new_app
      redirect_to :action => :index
      return
    end
    
    session[:application_id] = new_app.id
    redirect_to_home
  end
  
  def home
    @results_per_page = 10
    
    build_ao_messages_filter
    
    @ao_messages = AOMessage.paginate(
      :conditions => @ao_conditions,
      :order => 'id DESC',
      :page => @ao_page,
      :per_page => @results_per_page
      )
    
    build_at_messages_filter
      
    @at_messages = ATMessage.paginate(
      :conditions => @at_conditions,
      :order => 'id DESC',
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
      
    @channels = Channel.all(:conditions => ['application_id = ?', @application.id])
    @channels_queued_count = {}
    
    AOMessage.connection.select_all(
      "select count(*) as count, m.channel_id " +
      "from ao_messages m, channels c " +
      "where m.channel_id = c.id and m.application_id = #{@application.id} AND m.state = 'queued' " +
      "group by channel_id").each do |r|
      @channels_queued_count[r['channel_id'].to_i] = r['count'].to_i
    end
  end
  
  def edit_application
    @application = flash[:application] if not flash[:application].nil?
    @application.configuration ||= {} if not @application.nil?
  end
  
  def update_application
    app = params[:application]
    
    if app.nil?
      redirect_to_home
      return
    end
    
    @application.max_tries = app[:max_tries]
    @application.interface = app[:interface]
    
    @application.configuration ||= {}
    
    if not app[:configuration].nil?
      cfg = app[:configuration]
      @application.configuration.update({:url => cfg[:url]}) 
      @application.configuration.update({:cred_user => cfg[:cred_user]}) 
      @application.configuration.update({:cred_pass => cfg[:cred_pass]}) unless (cfg[:cred_pass].nil? or cfg[:cred_pass].chomp.empty?) and not (cfg[:cred_user].nil? or cfg[:cred_user].chomp.empty?)  
    end
      
    if !app[:password].chomp.empty?
      @application.salt = nil
      @application.password = app[:password]
      @application.password_confirmation = app[:password_confirmation]
    end
    
    if !@application.save
      @application.clear_password
      flash[:application] = @application
      redirect_to :action => :edit_application
    else
      flash[:notice] = 'Application was changed'
      redirect_to_home
    end
  end
  
  def edit_application_ao_routing
    @application = flash[:application] if not flash[:application].nil?
    @application.configuration ||= {} if not @application.nil?
  end
  
  def update_application_ao_routing
    app = params[:application]
    @application.ao_routing = app[:ao_routing]
    @application.ao_routing_test = app[:ao_routing_test]
    if !@application.save
      @application.clear_password
      flash[:application] = @application
      redirect_to :action => :edit_application_ao_routing
    else
      flash[:notice] = 'AO messages routing was changed'
      redirect_to_home
    end
  end
  
  def edit_application_at_routing
    @application = flash[:application] if not flash[:application].nil?
    @application.configuration ||= {} if not @application.nil?
  end
  
  def update_application_at_routing
    app = params[:application]
    @application.at_routing = app[:at_routing]
    @application.at_routing_test = app[:at_routing_test]
    if !@application.save
      @application.clear_password
      flash[:application] = @application
      redirect_to :action => :edit_application_at_routing
    else
      flash[:notice] = 'AT messages routing was changed'
      redirect_to_home
    end
  end
  
  def logoff
    session[:application_id] = nil
    redirect_to :action => :index
  end

end
