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

require 'test_helper'

class ApiUserChannelControllerTest < ActionController::TestCase
  def setup
    @user = User.make :authentication_token => '123456'
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret'
    @application2 = Application.make :account => @account

    @account2 = Account.make
    app2 = Application.make :account => @account2

    chan2 = QstServerChannel.make :account => @account2
    chan3 = QstServerChannel.make :account => @account, :application => @application2

    @user_account1 = UserAccount.make :user => @user, :account => @account, :role => 'admin'
    @user_account2 = UserAccount.make :user => @user, :account => @account2, :role => 'admin'
  end

  def authorize
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@user.email}", '123456')
  end

  test "index json" do
    authorize
    get :index, :format => 'json'
    assert_response :ok

    channels = JSON.parse @response.body
    assert_equal 2, channels.length
  end

end