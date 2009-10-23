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
    
    session[:application_id] = @application.id
    session[:application_name] = @application.name
    redirect_to :action => :home
  end
  
  def home
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
    if session[:application_id].nil?
      redirect_to :action => :index
      return
    end
    
    @application = Application.new
    @application.id = session[:application_id]
    @application.name = session[:application_name]
  end

end