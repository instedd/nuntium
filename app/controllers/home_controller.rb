require 'will_paginate'

class HomeController < AccountAuthenticatedController

  include MessageFilters
  include RulesControllerCommon

  before_filter :check_login, :except => [:login, :create_account]
  before_filter :load_channels_and_applications, :only => [:interactions, :applications, :channels, :ao_messages, :at_messages, :logs]
  after_filter :compress

  before_filter :check_application, :only => [:edit_application, :update_application, :delete_application]

  ResultsPerPage = 10

  def index
    # This is to avoid one redirect
    load_channels_and_applications
    render "applications"
  end

  def interactions
  end

  def settings
  end

  def applications
  end

  def channels
  end

  def ao_messages
    build_ao_messages_filter

    @ao_messages = AOMessage.paginate(
      :conditions => @ao_conditions,
      :order => 'id DESC',
      :page => @ao_page,
      :per_page => ResultsPerPage
      )
  end

  def at_messages
    build_at_messages_filter

    @at_messages = ATMessage.paginate(
      :conditions => @at_conditions,
      :order => 'id DESC',
      :page => @at_page,
      :per_page => ResultsPerPage
      )
  end

  def logs
    build_logs_filter

    @logs = AccountLog.paginate(
      :conditions => @log_conditions,
      :order => 'id DESC',
      :page => params[:logs_page],
      :per_page => ResultsPerPage
      )
  end

  def visualizations
  end

  def login
    account = params[:account]
    return redirect_to_home if account.nil?

    @account = Account.find_by_name account[:name]
    if @account.nil? || !@account.authenticate(account[:password])
      @account = Account.new :name => account[:name]
      flash[:login_error] = 'Invalid name/password'
      return render :index
    end

    flash[:login_error] = nil
    session[:account_id] = @account.id
    redirect_to_home
  end

  def create_account
    return render :text => 'This funcionality has been disabled, contact the system administrator' if AccountCreationDisabled

    account = params[:new_account]
    return redirect_to_home if account.nil?

    flash[:login_error] = nil

    @new_account = Account.new(account)
    if !@new_account.save
      @new_account.clear_password
      return render :index
    end

    session[:account_id] = @new_account.id
    redirect_to_home
  end

  def update_account
    account = params[:account]
    return redirect_to_home if account.nil?

    @account.max_tries = account[:max_tries]
    @account.alert_emails = account[:alert_emails]

    if !account[:password].blank?
      @account.salt = nil
      @account.password = account[:password]
      @account.password_confirmation = account[:password_confirmation]
    end

    Rails.logger.info @account
    if !@account.save
      @account.clear_password
      render :settings
    else
      flash[:notice] = 'Settings were changed'
      redirect_to :settings
    end
  end

  def update_application_routing_rules
    @account.app_routing_rules = get_rules :apprules

    if !@account.save
      render :applications
    else
      flash[:notice] = 'Application Routing Rules were changed'
      redirect_to :applications
    end
  end

  def new_application
    @application = Application.new unless @application
    @selected_tab = :applications
  end

  def create_application
    app = params[:application]
    return redirect_to_home if app.nil?

    @application = Application.new(app)
    @application.account_id = @account.id

    cfg = app[:configuration]
    @application.configuration = app[:configuration]
    @application.use_address_source = cfg[:use_address_source]
    @application.ao_rules = get_rules :aorules
    @application.at_rules = get_rules :atrules
    @application.strategy = cfg[:strategy]

    if !@application.save
      return render :new_application
    end

    flash[:notice] = 'Application was created'
    redirect_to :applications
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
    @application.at_rules = get_rules :atrules

    if app[:password].present?
      @application.salt = nil
      @application.password = app[:password]
      @application.password_confirmation = app[:password_confirmation]
    end

    if !@application.save
      return render :new_application
    end

    flash[:notice] = "Application #{@application.name} was changed"
    redirect_to :applications
  end

  def delete_application
    @application.destroy

    flash[:notice] = 'Application was deleted'
    redirect_to :applications
  end

  def check_application
    @application = @account.find_application params[:id]
    redirect_to_home if @application.nil?
  end

  def logoff
    session[:account_id] = nil
    redirect_to :action => :index
  end

  private

  def load_channels_and_applications
    @channels = @account.channels
    @applications = @account.applications
  end

end
