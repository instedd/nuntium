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

class SettingsControllerTest < ActionController::TestCase
  setup do
    @user = User.make
    @account = @user.create_account Account.make_unsaved(:password => 'account_pass')
    sign_in @user
  end

  test "edit account succeeds" do
    post :update, :account => {:max_tries => 1, :password => '', :password_confirmation => ''}

    # Go to settings
    assert_redirected_to settings_path
    assert_equal 'Settings updated', flash[:notice]

    # The account was changed
    accounts = Account.all
    assert_equal 1, accounts.length

    account = accounts[0]
    assert_equal 1, account.max_tries
    assert(account.authenticate('account_pass'))
  end

  test "edit account change password succeeds" do
    post :update, :account => {:max_tries => 3, :password => 'new_pass', :password_confirmation => 'new_pass'}

    # Go to settings
    assert_redirected_to settings_path
    assert_equal 'Settings updated', flash[:notice]

    # The account was changed
    accounts = Account.all
    assert_equal 1, accounts.length

    account = accounts[0]
    assert(account.authenticate('new_pass'))
  end

  test "edit account fails with max tries" do
    post :update, :account => {:max_tries => 'foo', :password => '', :password_confirmation => ''}
    assert_template 'show'
  end
end
