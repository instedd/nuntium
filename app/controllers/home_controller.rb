require 'will_paginate'

class HomeController < AccountAuthenticatedController

  include MessageFilters
  include RulesControllerCommon

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
      
    @channels = @account.channels
    @channels_queued_count = Hash.new 0
    
    AOMessage.connection.select_all(
      "select count(*) as count, m.channel_id " <<
      "from ao_messages m, channels c " <<
      "where m.channel_id = c.id and m.account_id = #{@account.id} AND m.state = 'queued' " <<
      "group by channel_id").each do |r|
      @channels_queued_count[r['channel_id'].to_i] = r['count'].to_i
    end
    
    @applications = @account.applications
  end
  
  def edit_account
  end
  
  def update_account
    account = params[:account]
    return redirect_to_home if account.nil?
    
    @account.max_tries = account[:max_tries]
      
    if !account[:password].blank?
      @account.salt = nil
      @account.password = account[:password]
      @account.password_confirmation = account[:password_confirmation]
    end
    
    @account.app_routing_rules = get_rules :apprules
    
    if !@account.save
      @account.clear_password
      render :edit_account
    else
      redirect_to_home 'Account was changed'
    end
  end
  
  def new_application
    @application = Application.new unless @application
  end
  
  def create_application
    app = params[:application]
    return redirect_to_home if app.nil?
    
    @application = Application.new(app)
    @application.account_id = @account.id
    
    cfg = app[:configuration]
    @application.use_address_source = cfg[:use_address_source] == '1'
    @application.ao_rules = get_rules :aorules
    @application.strategy = cfg[:strategy]
    
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
    
    @application.interface = app[:interface]
    
    @application.configuration = app[:configuration]
    @application.use_address_source = false if @application.configuration[:use_address_source] != '1' 
    @application.ao_rules = get_rules :aorules
    
    if app[:password].present?
      @application.salt = nil
      @application.password = app[:password]
      @application.password_confirmation = app[:password_confirmation]
    end
    
    if !@application.save
      return render :new_application
    end
    
    redirect_to_home "Application #{@application.name} was changed"
  end
  
  def delete_application
    @application.destroy
    
    redirect_to_home 'Application was deleted'
  end
  
  def check_application
    @application = @account.find_application params[:id]
    redirect_to_home if @application.nil?
  end
  
  def logoff
    session[:account_id] = nil
    redirect_to :action => :index
  end

end
