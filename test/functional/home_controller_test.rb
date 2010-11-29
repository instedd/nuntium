require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "login succeeds" do
    account = Account.make :password => 'account_pass'

    get :login, :account => {:name => account.name, :password => 'account_pass'}

    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'index')

    # Account id was saved in session
    assert_equal account.id, session[:account_id]
  end

  test "create account succeeds" do
    attrs = Account.plan :password => 'account_pass'

    get :create_account, :new_account => attrs

    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'index')

    # The account was created
    accounts = Account.all
    assert_equal 1, accounts.length

    account = accounts[0]
    assert_equal attrs[:name], accounts[0].name
    assert accounts[0].authenticate(attrs[:password])

    # Account was saved in session
    assert_equal account.id, session[:account_id]
  end

  test "edit account succeeds" do
    account = Account.make :password => 'account_pass'

    get :update_account, {:account => {:max_tries => 1, :password => '', :password_confirmation => ''}}, {:account_id => account.id}

    # Go to settings
    assert_redirected_to(:controller => 'home', :action => 'settings')
    assert_equal 'Settings were changed', flash[:notice]

    # The account was changed
    accounts = Account.all
    assert_equal 1, accounts.length

    account = accounts[0]
    assert_equal 1, account.max_tries
    assert(account.authenticate('account_pass'))
  end

  test "edit account change password succeeds" do
    account = Account.make :password => 'account_pass'

    get :update_account, {:account => {:max_tries => 3, :password => 'new_pass', :password_confirmation => 'new_pass'}}, {:account_id => account.id}

    # Go to settings
    assert_redirected_to(:controller => 'home', :action => 'settings')
    assert_equal 'Settings were changed', flash[:notice]

    # The account was changed
    accounts = Account.all
    assert_equal 1, accounts.length

    account = accounts[0]
    assert(account.authenticate('new_pass'))
  end

  test "home" do
    account = Account.make
    get :index, {}, {:account_id => account.id}
    assert_template "applications"
  end

  # ------------------------ #
  # Validations tests follow #
  # ------------------------ #

  test "edit account fails with max tries" do
    account = Account.make
    get :update_account, {:account => {:max_tries => 'foo', :password => '', :password_confirmation => ''}}, {:account_id => account.id}
    assert_template 'settings'
  end

  test "login fails wrong name" do
    account = Account.make
    get :login, :account => {:name => 'wrong_account', :password => 'account_pass'}
    assert_template 'index'
  end

  test "login fails wrong pass" do
    account = Account.make
    get :login, :account => {:name => account.name, :password => 'wrong_pass'}
    assert_template 'index'
  end

  test "create account fails name is empty" do
    account = Account.make
    get :create_account, :new_account => {:name => '   ', :password=> 'foo'}
    assert_template 'index'
  end

end
