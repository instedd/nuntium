require 'test_helper'

class SettingsControllerTest < ActionController::TestCase
  test "edit account succeeds" do
    account = Account.make :password => 'account_pass'

    post :update, {:account => {:max_tries => 1, :password => '', :password_confirmation => ''}}, {:account_id => account.id}

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
    account = Account.make :password => 'account_pass'

    post :update, {:account => {:max_tries => 3, :password => 'new_pass', :password_confirmation => 'new_pass'}}, {:account_id => account.id}

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
    account = Account.make
    post :update, {:account => {:max_tries => 'foo', :password => '', :password_confirmation => ''}}, {:account_id => account.id}
    assert_template 'show'
  end
end
