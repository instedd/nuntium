require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "login succeeds" do
    account = Account.create({:name => 'account', :password => 'account_pass'});
    
    get :login, :account => {:name => 'account', :password => 'account_pass'}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    
    # Account id was saved in session
    assert_equal account.id, session[:account_id]
  end
  
  test "create account succeeds" do
    get :create_account, :new_account => {:name => 'account', :password => 'account_pass', :password_confirmation => 'account_pass'}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    
    # The account was created
    accounts = Account.all
    assert_equal 1, accounts.length
    
    account = accounts[0]
    assert_equal 'account', accounts[0].name
    assert(accounts[0].authenticate('account_pass'))
    
    # Account was saved in session
    assert_equal account.id, session[:account_id]
  end
  
  test "edit account succeeds" do
    account = Account.create({:name => 'account', :password => 'account_pass', :interface => 'rss' })
    
    get :update_account, {:account => {:max_tries => 1, :interface => 'qst_client', :configuration => { :url => 'myurl' }, :password => '', :password_confirmation => ''}}, {:account_id => account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Account was changed', flash[:notice]
    
    # The account was changed
    accounts = Account.all
    assert_equal 1, accounts.length
    
    account = accounts[0]
    assert_equal 1, account.max_tries
    assert(account.authenticate('account_pass'))
  end
  
  test "edit account change password succeeds" do
    account = Account.create({:name => 'account', :password => 'account_pass', :interface => 'rss'})
    
    get :update_account, {:account => {:max_tries => 3, :interface => 'rss', :password => 'new_pass', :password_confirmation => 'new_pass'}}, {:account_id => account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Account was changed', flash[:notice]
    
    # The account was changed
    accounts = Account.all
    assert_equal 1, accounts.length
    
    account = accounts[0]
    assert(account.authenticate('new_pass'))
  end

  test "home" do
    account = Account.create({:name => 'account', :password => 'account_pass'});
    get :home, {}, {:account_id => account.id}
    assert_template 'home/home.html.erb'
  end
  
  # ------------------------ #
  # Validations tests follow #
  # ------------------------ #
  
  test "edit account fails with max tries" do
    account = Account.create({:name => 'account', :password => 'account_pass'})
    get :update_account, {:account => {:max_tries => 'foo', :password => '', :password_confirmation => ''}}, {:account_id => account.id}
    assert_template 'edit_account'
  end
  
  test "edit account fails with invalid interface" do
    account = Account.create({:name => 'account', :password => 'account_pass', :interface => 'rss'})
    get :update_account, {:account => {:max_tries => '1', :interface => 'invalid' , :password => '', :password_confirmation => ''}}, {:account_id => account.id}
    assert_template 'edit_account'
  end
  
  test "login fails wrong name" do
    account = Account.create({:name => 'account', :password => 'account_pass'});
    get :login, :account => {:name => 'wrong_account', :password => 'account_pass'}
    assert_template 'index'
  end
  
  test "login fails wrong pass" do
    account = Account.create({:name => 'account', :password => 'account_pass'});
    get :login, :account => {:name => 'account', :password => 'wrong_pass'}
    assert_template 'index'
  end
  
  test "create account fails name is empty" do
    account = Account.create({:name => 'account', :password => 'account_pass'});
    get :create_account, :new_account => {:name => '   ', :password=> 'foo'}
    assert_template 'index'
  end
  
end
