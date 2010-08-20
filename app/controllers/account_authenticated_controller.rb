class AccountAuthenticatedController < ApplicationController

  def check_login
    if session[:account_id].nil?
      return render :template => 'home/index'
    end
    
    @account_id = session[:account_id]
    @account = Account.find_by_id @account_id
    if @account.nil?
      session.delete :account_id
      return render :template => 'home/index'
    end
  end
  
  def redirect_to_home(msg = nil)
    flash[:notice] = msg if msg
    redirect_to :controller => :home, :action => :index
  end

end
