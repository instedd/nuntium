class HomeController < ApplicationController

  before_filter :check_login, :except => [:index, :login, :create_application]

  def index
    @application = flash[:application]
    @new_application = flash[:new_application]
  end
  
  def login
    app = params[:application]
    @application = Application.find_by_name app[:name]
    if @application.nil? || !@application.authenticate(app[:password])
      flash[:application] = Application.new(:name => app[:name])
      flash[:notice] = 'Invalid name/password'
      redirect_to :action => :index
      return
    end
    
    @application.salt = nil
    @application.password = nil
    
    session[:application] = @application
    redirect_to :action => :home
  end
  
  def create_application
    app = params[:new_application]
    
    new_app = Application.new(app)
    if !new_app.save
      flash[:new_application] = Application.new(:name => app[:name])
      flash[:new_notice] = new_app.errors.full_messages.join('<br/>')
      redirect_to :action => :index
      return
    end
    
    new_app.salt = nil
    new_app.password = nil
    
    session[:application] = new_app
    redirect_to :action => :home
  end
  
  def home
    @channels = Channel.all(:conditions => ['application_id = ?', @application.id])
    @ao_messages = AOMessage.all(
      :conditions => ['application_id = ?', @application.id], 
      :order => 'timestamp DESC',
      :limit => 10)
    @at_messages = ATMessage.all(
      :conditions => ['application_id = ?', @application.id], 
      :order => 'timestamp DESC',
      :limit => 10)
  end
  
  def edit_application
  end
  
  def update_application
    app = params[:application]
    
    existing_app = Application.find @application.id
    existing_app.max_tries = app[:max_tries]
    
    if !existing_app.save
      flash[:notice] = existing_app.errors.full_messages.join('<br/>')
      redirect_to :action => :edit_application
      return
    end
    
    existing_app.salt = nil
    existing_app.password = nil
    
    session[:application] = existing_app
    redirect_to :action => :home
  end
  
  def new_channel
  end
  
  def create_channel
  end
  
  def edit_channel
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