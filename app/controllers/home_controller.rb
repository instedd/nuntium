class HomeController < ApplicationController

  before_filter :check_login, :except => [:index, :login]

  def index
    @application = flash[:application]
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
    session[:application] = @application
    redirect_to :action => :home
  end
  
  def home
    @channels = Channel.all('application_id = ?', @application.id)
    @ao_messages = AOMessage.all(
      :conditions => ['application_id = ?', @application.id], 
      :order => 'timestamp DESC',
      :limit => 10)
    @at_messages = ATMessage.all(
      :conditions => ['application_id = ?', @application.id], 
      :order => 'timestamp DESC',
      :limit => 10)
  end
  
  def check_login
    if session[:application].nil?
      redirect_to :action => :index
      return
    end
    
    @application = session[:application]
  end

end