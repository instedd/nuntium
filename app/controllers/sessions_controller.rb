class SessionsController < ApplicationController
  skip_filter :check_login, :only => [:new, :create, :register]

  def new
    @account = Account.new
    @new_account = Account.new
  end

  def create
    @account, @app = Account.authenticate params[:account][:name], params[:account][:password]
    if @account
      flash[:login_error] = nil
      @app ? (session[:application_id] = @app.id) : (session[:account_id] = @account.id)
      redirect_to root_path
      return
    end

    @account = Account.new :name => params[:account][:name]
    @new_account = Account.new
    flash[:login_error] = 'Invalid name/password'
    render :new
  end

  def register
    return render :text => 'This funcionality has been disabled, contact the system administrator' if Nuntium::AccountCreationDisabled

    flash[:login_error] = nil

    @new_account = Account.new params[:account]
    if @new_account.save
      session[:account_id] = @new_account.id
      redirect_to root_path
    else
      @new_account.password = ''
      @new_account.password_confirmation = ''
      @account = Account.new
      render :new
    end
  end

  def destroy
    session[:account_id] = nil
    session[:application_id] = nil
    redirect_to new_session_path
  end
end
