# Copyright (C) 2009-2012, InSTEDD
# 
# This file is part of Nuntium.
# 
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

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
