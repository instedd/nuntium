require 'will_paginate'

class HomeController < AuthenticatedController

  include MessageFilters

  before_filter :check_login, :except => [:index, :login, :create_application]
  after_filter :compress, :only => [:index, :login, :home, :edit_application, :edit_application_ao_routing, :edit_application_at_routing]

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
    return redirect_to_home if app.nil?
    
    @application = Application.find_by_name app[:name]
    if @application.nil? || !@application.authenticate(app[:password])
      flash[:application] = Application.new(:name => app[:name])
      flash[:notice] = 'Invalid name/password'
      return redirect_to :action => :index
    end
    
    session[:application_id] = @application.id
    redirect_to_home
  end
  
  def create_application
    app = params[:new_application]
    return redirect_to_home if app.nil?
    
    new_app = Application.new(app)
    if !new_app.save
      new_app.clear_password
      flash[:new_application] = new_app
      return redirect_to :action => :index
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
      
    build_logs_filter
      
    @logs = ApplicationLog.paginate(
      :conditions => @log_conditions,
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
    
    @failed_alerts = Alert.all(:conditions => ['application_id = ? and failed = ?', @application.id, true])
  end
  
  def edit_application
    @application = flash[:application] if not flash[:application].nil?
  end
  
  def update_application
    app = params[:application]
    return redirect_to_home if app.nil?
    
    @application.max_tries = app[:max_tries]
    @application.interface = app[:interface]
    
    if not app[:configuration].nil?
      cfg = app[:configuration]
      
      if cfg[:use_address_source] == '1'
        @application.configuration[:use_address_source] = 1
      else
        @application.configuration.delete :use_address_source
      end
      
      @application.configuration.update({:url => cfg[:url]}) 
      @application.configuration.update({:cred_user => cfg[:cred_user]}) 
      @application.configuration.update({:cred_pass => cfg[:cred_pass]}) unless (cfg[:cred_pass].nil? or cfg[:cred_pass].blank?) and not (cfg[:cred_user].nil? or cfg[:cred_user].blank?)  
    end
      
    if !app[:password].blank?
      @application.salt = nil
      @application.password = app[:password]
      @application.password_confirmation = app[:password_confirmation]
    end
    
    if !@application.save
      @application.clear_password
      flash[:application] = @application
      redirect_to :action => :edit_application
    else
      redirect_to_home 'Application was changed'
    end
  end
  
  def edit_application_ao_routing
    @application = flash[:application] if not flash[:application].nil?
  end
  
  def update_application_ao_routing
    app = params[:application]
    cfg = app[:configuration]
    @application.configuration[:ao_routing] = cfg[:ao_routing]
    @application.configuration[:ao_routing_test] = cfg[:ao_routing_test]
    if !@application.save
      flash[:application] = @application
      redirect_to :action => :edit_application_ao_routing
    else
      redirect_to_home 'AO messages routing was changed'
    end
  end
  
  def edit_application_at_routing
    @application = flash[:application] if not flash[:application].nil?
  end
  
  def update_application_at_routing
    app = params[:application]
    cfg = app[:configuration]
    @application.configuration[:at_routing] = cfg[:at_routing]
    @application.configuration[:at_routing_test] = cfg[:at_routing_test]
    if !@application.save
      flash[:application] = @application
      redirect_to :action => :edit_application_at_routing
    else
      redirect_to_home 'AT messages routing was changed'
    end
  end
  
  def edit_application_alerts
    @application = flash[:application] if not flash[:application].nil?
    @channels = @application.channels
    @alert_configurations = AlertConfiguration.find_all_by_application_id @application.id
  end
  
  def update_application_alerts
    # Validation
    params[:channel].each do |chan|
      next if !chan[1][:activated]
      
      if chan[1][:from].blank? || chan[1][:to].blank?
        @application.errors.add(:alert_configuration, 'You left a <i>from</i> or <i>to</i> field blank for an alert-activated channel') 
        flash[:application] = @application
        return redirect_to :action => :edit_application_alerts
      end
    end
    
    # Alert logic validation
    app = params[:application]
    cfg = app[:configuration]
    @application.configuration[:alert] = cfg[:alert]
    
    if !@application.save
      flash[:application] = @application
      return redirect_to :action => :edit_application_alerts
    end
  
    AlertConfiguration.delete_all(['application_id = ?', @application.id])
    
    params[:channel].each do |chan|
      next if !chan[1][:activated]
      AlertConfiguration.create!(:application_id => @application.id, :channel_id => chan[0].to_i, :from => chan[1][:from], :to => chan[1][:to]) 
    end
    
    redirect_to_home 'Alerts were changed'
  end
  
  def find_address_source
    chan = Channel.first(:joins => :address_sources, :conditions => ['address_sources.application_id = ? AND address_sources.address = ?', @application.id, params[:address]]);
    render :text => chan.nil? ? '' : chan.name
  end
  
  def delete_failed_alerts
    Alert.delete_all(['application_id = ? and failed = ?', @application.id, true])
    redirect_to_home
  end
  
  def logoff
    session[:application_id] = nil
    redirect_to :action => :index
  end

end
