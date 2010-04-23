require 'will_paginate'

class HomeController < AuthenticatedController

  include MessageFilters

  before_filter :check_login, :except => [:index, :login, :create_account]
  after_filter :compress, :only => [:index, :login, :home, :edit_account]
  
  before_filter :check_application, :only => [:edit_application, :update_application, :delete_application]

  def index
    if !session[:account_id].nil?
      redirect_to_home
      return
    end
  end
  
  def login
    account = params[:account]
    return redirect_to_home if account.nil?
    
    @account = Account.find_by_name account[:name]
    if @account.nil? || !@account.authenticate(account[:password])
      @account.clear_password unless @account.nil?
      flash[:notice] = 'Invalid name/password'
      return render :index
    end
    
    flash[:notice] = nil
    session[:account_id] = @account.id
    redirect_to_home
  end
  
  def create_account
    return render :text => 'This funcionality has been disabled, contact the system administrator' if AccountCreationDisabled
  
    account = params[:new_account]
    return redirect_to_home if account.nil?
    
    @new_account = Account.new(account)
    if !@new_account.save
      @new_account.clear_password
      return render :index
    end
    
    session[:account_id] = @new_account.id
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
      
    @logs = AccountLog.paginate(
      :conditions => @log_conditions,
      :order => 'id DESC',
      :page => params[:logs_page],
      :per_page => @results_per_page
      )
      
    @channels = Channel.all(:conditions => ['account_id = ?', @account.id])
    @channels_queued_count = Hash.new 0
    
    AOMessage.connection.select_all(
      "select count(*) as count, m.channel_id " <<
      "from ao_messages m, channels c " <<
      "where m.channel_id = c.id and m.account_id = #{@account.id} AND m.state = 'queued' " <<
      "group by channel_id").each do |r|
      @channels_queued_count[r['channel_id'].to_i] = r['count'].to_i
    end
    
    @applications = Application.all(:conditions => ['account_id = ?', @account.id])
    
    @failed_alerts = Alert.all(:conditions => ['account_id = ? and failed = ?', @account.id, true])
  end
  
  def edit_account
  end
  
  def update_account
    account = params[:account]
    return redirect_to_home if account.nil?
    
    @account.max_tries = account[:max_tries]
    @account.interface = account[:interface]
    
    if not account[:configuration].nil?
      cfg = account[:configuration]
      
      if cfg[:use_address_source] == '1'
        @account.configuration[:use_address_source] = 1
      else
        @account.configuration.delete :use_address_source
      end
      
      @account.configuration.update({:url => cfg[:url]}) 
      @account.configuration.update({:cred_user => cfg[:cred_user]}) 
      @account.configuration.update({:cred_pass => cfg[:cred_pass]}) unless (cfg[:cred_pass].nil? or cfg[:cred_pass].blank?) and not (cfg[:cred_user].nil? or cfg[:cred_user].blank?)  
    end
      
    if !account[:password].blank?
      @account.salt = nil
      @account.password = account[:password]
      @account.password_confirmation = account[:password_confirmation]
    end
    
    if !@account.save
      @account.clear_password
      render :edit_account
    else
      redirect_to_home 'Account was changed'
    end
  end
  
  def setup_account_alerts
    @channels = Channel.all(:conditions => ['account_id = ? and (direction = ? or direction = ?)', @account.id, Channel::Outgoing, Channel::Bidirectional])
    @alert_configurations = AlertConfiguration.find_all_by_account_id @account.id
  end
  
  def edit_account_alerts
    setup_account_alerts
  end
  
  def update_account_alerts
    # Validation
    params[:channel].each do |chan|
      next if !chan[1][:activated]
      
      if chan[1][:from].blank? || chan[1][:to].blank?
        @account.errors.add(:alert_configuration, 'You left a <i>from</i> or <i>to</i> field blank for an alert-activated channel') 
        setup_account_alerts
        return render :edit_account_alerts
      end
    end
    
    # Alert logic validation
    account = params[:account]
    cfg = account[:configuration]
    @account.configuration[:alert] = cfg[:alert]
    
    if !@account.save
      setup_account_alerts
      return render :edit_account_alerts
    end
  
    AlertConfiguration.delete_all(['account_id = ?', @account.id])
    
    params[:channel].each do |chan|
      next if !chan[1][:activated]
      AlertConfiguration.create!(:account_id => @account.id, :channel_id => chan[0].to_i, :from => chan[1][:from], :to => chan[1][:to]) 
    end
    
    redirect_to_home 'Alerts were changed'
  end
  
  def new_application
    @application = Application.new unless @application
  end
  
  def create_application
    app = params[:application]
    return redirect_to_home if app.nil?
    
    @application = Application.new(app)
    @application.account_id = @account.id
    if !@application.save
      return render :new_application
    end
    
    redirect_to_home 'Application was created'
  end
  
  def edit_application
    render :new_application
  end
  
  def update_application
    app = params[:application]
    return redirect_to_home if app.nil?
    
    @application.attributes = app
    if !@application.save
      return render :new_application
    end
    
    redirect_to_home "Application #{@application.name} was changed"
  end
  
  def delete_application
    @application.destroy
    
    redirect_to_home 'Application was deleted'
  end
  
  def find_address_source
    chan = Channel.first(:joins => :address_sources, :conditions => ['address_sources.account_id = ? AND address_sources.address = ?', @account.id, params[:address]]);
    render :text => chan.nil? ? '' : chan.name
  end
  
  def delete_failed_alerts
    Alert.delete_all(['account_id = ? and failed = ?', @account.id, true])
    redirect_to_home
  end
  
  def check_application
    @application = Application.find_by_id params[:id]
    redirect_to_home if @application.nil? || @application.account_id != @account.id
  end
  
  def logoff
    session[:account_id] = nil
    redirect_to :action => :index
  end

end
