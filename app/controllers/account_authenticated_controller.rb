class AccountAuthenticatedController < ApplicationController

  def check_login
    if session[:account_id].nil?
      render :template => 'home/index'
      compress
      return
    end

    @account_id = session[:account_id]
    @account = Account.find_by_id @account_id
    if @account.nil?
      session.delete :account_id
      render :template => 'home/index'
      compress
      return
    end
  end

  def redirect_to_home(msg = nil)
    flash[:notice] = msg if msg
    redirect_to :controller => :home, :action => :index
  end

end
