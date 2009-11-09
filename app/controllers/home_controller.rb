require 'will_paginate'

class HomeController < ApplicationController

  before_filter :check_login, :except => [:index, :login, :create_application]

  def index
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
    
    # AO filtering
    @ao_page = params[:ao_page]
    @ao_page = 1 if @ao_page.blank?    
    @ao_search = params[:ao_search]
    @ao_from = params[:ao_from]
    @ao_to = params[:ao_to]
    @ao_state = params[:ao_state]
    @ao_previous_filter = params[:ao_previous_filter]
    @ao_filter = @ao_search.to_s + @ao_from.to_s + @ao_to.to_s + @ao_state.to_s
    @ao_page = 1 if @ao_previous_filter != @ao_filter
    
    @ao_conditions = ['application_id = :application_id', { :application_id => @application.id }]
    if !@ao_search.blank?
      @ao_conditions[0] += ' AND (guid = :search OR [from] LIKE :search OR [to] LIKE :search OR subject LIKE :search OR body LIKE :search)'
      @ao_conditions[1][:search] = '%' + @ao_search + '%'
      
      # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
      @ao_page = 1 if !@ao_previous_search.blank? and @ao_previous_search != @ao_search
    end
    if !@ao_from.blank?
      begin
        from = Time.parse(@ao_from)
        @ao_conditions[0] += ' AND timestamp >= :from'
        @ao_conditions[1][:from] = from
      rescue
        @ao_from = 'ERROR: ' + @ao_from
      end
    end
    if !@ao_to.blank?
      begin
        to = Time.parse(@ao_to)
        @ao_conditions[0] += ' AND timestamp <= :to'
        @ao_conditions[1][:to] = to
      rescue
        @ao_to = 'ERROR: ' + @ao_to
      end
    end
    if !@ao_state.blank?
      @ao_conditions[0] += ' AND state LIKE :state'
      @ao_conditions[1][:state] = '%' + @ao_state + '%'
    end
    
    @ao_messages = AOMessage.paginate(
      :conditions => @ao_conditions,
      :order => 'timestamp DESC',
      :page => @ao_page,
      :per_page => @results_per_page
      )
      
    # AO filtering
    @at_page = params[:at_page]
    @at_page = 1 if @at_page.blank?    
    @at_search = params[:at_search]
    @at_previous_search = params[:at_previous_search]
    @at_from = params[:at_from]
    @at_to = params[:at_to]
    @at_state = params[:at_state]
    @at_previous_filter = params[:at_previous_filter]
    @at_filter = @at_search.to_s + @at_from.to_s + @at_to.to_s + @at_state.to_s
    @at_page = 1 if @at_previous_filter != @at_filter
    
    @at_conditions = ['application_id = :application_id', { :application_id => @application.id }]
    if !@at_search.blank?
      @at_conditions[0] += ' AND (guid = :search OR [from] LIKE :search OR [to] LIKE :search OR subject LIKE :search OR body LIKE :search)'
      @at_conditions[1][:search] = '%' + @at_search + '%'
      
      # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
      @at_page = 1 if !@at_previous_search.blank? and @at_previous_search != @at_search
    end
    if !@at_from.blank?
      begin
        from = Time.parse(@at_from)
        @at_conditions[0] += ' AND timestamp >= :from'
        @at_conditions[1][:from] = from
      rescue
        @at_from = 'ERROR: ' + @at_from
      end
    end
    if !@at_to.blank?
      begin
        to = Time.parse(@at_to)
        @at_conditions[0] += ' AND timestamp <= :to'
        @at_conditions[1][:to] = to
      rescue
        @at_to = 'ERROR: ' + @at_to
      end
    end
    if !@at_state.blank?
      @at_conditions[0] += ' AND state LIKE :state'
      @at_conditions[1][:state] = '%' + @at_state + '%'
    end
    
    @at_messages = ATMessage.paginate(
      :conditions => @at_conditions,
      :order => 'timestamp DESC',
      :page => @at_page,
      :per_page => @results_per_page
      )
      
    # Channels
    @channels = @application.channels.all
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
    
    if !@channel.save
      @channel.clear_password
      flash[:channel] = @channel
      redirect_to :action => :new_channel
      return
    end
    
    flash[:notice] = 'Channel was created'
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
    
    if !@channel.save
      @channel.clear_password
      flash[:channel] = @channel
      redirect_to :action => :edit_channel
      return
    end
    
    flash[:notice] = 'Channel was changed'
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