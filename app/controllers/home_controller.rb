require 'will_paginate'

class HomeController < AuthenticatedController

  include MessageFilters

  before_filter :check_login, :except => [:index, :login, :create_application]

  def index
    if !session[:application].nil?
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
    
    @application.clear_password
    
    session[:application] = @application
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
    
    new_app.clear_password
    
    session[:application] = new_app
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
      
    @channels = @application.channels.all
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
    
    existing_app = Application.find @application.id
    existing_app.max_tries = app[:max_tries]
    existing_app.interface = app[:interface]
    
    existing_app.configuration ||= {}
    
    if not app[:configuration].nil?
      cfg = app[:configuration]
      existing_app.configuration.update({:url => cfg[:url]}) 
      existing_app.configuration.update({:cred_user => cfg[:cred_user]}) 
      existing_app.configuration.update({:cred_pass => cfg[:cred_pass]}) unless (cfg[:cred_pass].nil? or cfg[:cred_pass].chomp.empty?) and not (cfg[:cred_user].nil? or cfg[:cred_user].chomp.empty?)  
    end
      
    if !app[:password].chomp.empty?
      existing_app.salt = nil
      existing_app.password = app[:password]
      existing_app.password_confirmation = app[:password_confirmation]
    end
    
    if !existing_app.save
      existing_app.clear_password
      flash[:application] = existing_app
      redirect_to :action => :edit_application
    else    
      existing_app.clear_password
      flash[:notice] = 'Application was changed'
      session[:application] = existing_app
      redirect_to_home
    end
  end
  
  def logoff
    session[:application] = nil
    redirect_to :action => :index
  end

end
