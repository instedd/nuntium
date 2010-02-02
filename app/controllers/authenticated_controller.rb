class AuthenticatedController < ApplicationController

  def check_login
    if session[:application_id].nil?
      redirect_to :controller => :home, :action => :index
      return
    end
    
    @application_id = session[:application_id]
    @application = Application.find_by_id @application_id
    if @application.nil?
      session.delete :application_id
      redirect_to :controller => :home, :action => :index
      return
    end
  end
  
  def redirect_to_home(msg = nil)
    flash[:notice] = msg if msg
    redirect_to :controller => :home, :action => :home
  end

end