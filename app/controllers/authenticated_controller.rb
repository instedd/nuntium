class AuthenticatedController < ApplicationController

  def check_login
    if session[:application].nil?
      redirect_to :action => :index
      return
    end
    
    @application = session[:application]
  end
  
  def redirect_to_home
    redirect_to :controller => :home, :action => :home
  end

end