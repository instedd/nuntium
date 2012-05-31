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

class SessionsControllerTest < ActionController::TestCase
  test "login succeeds" do
    account = Account.make :password => 'account_pass'

    post :create, :account => {:name => account.name, :password => 'account_pass'}

    # Go to account home page
    assert_redirected_to root_path

    # Account id was saved in session
    assert_equal account.id, session[:account_id]
  end

  test "create account succeeds" do
    attrs = Account.plan :password => 'account_pass'

    post :register, :account => attrs

    # Go to account home page
    assert_redirected_to root_path

    # The account was created
    accounts = Account.all
    assert_equal 1, accounts.length

    account = accounts[0]
    assert_equal attrs[:name], accounts[0].name
    assert accounts[0].authenticate(attrs[:password])

    # Account was saved in session
    assert_equal account.id, session[:account_id]
  end

  test "login fails wrong name" do
    account = Account.make
    post :create, :account => {:name => 'wrong_account', :password => 'account_pass'}
    assert_template 'new'
  end

  test "login fails wrong pass" do
    account = Account.make
    post :create, :account => {:name => account.name, :password => 'wrong_pass'}
    assert_template 'new'
  end

  test "create account fails name is empty" do
    account = Account.make
    post :register, :new_account => {:name => '   ', :password=> 'foo'}
    assert_template 'new'
  end
end
