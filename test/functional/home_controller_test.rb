require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "login succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :login, :application => {:name => 'app', :password => 'app_pass'}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    
    # App was saved in session
    assert_equal app.id, session[:application].id
    assert_equal app.name, session[:application].name
    
    # But salt and password are not
    assert_nil session[:application].salt
    assert_nil session[:application].password
  end
  
  test "create app succeeds" do
    get :create_application, :new_application => {:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    
    # The app was created
    apps = Application.all
    assert_equal 1, apps.length
    
    app = apps[0]
    assert_equal 'app', apps[0].name
    assert(apps[0].authenticate('app_pass'))
    
    # App was saved in session
    assert_equal app.id, session[:application].id
    assert_equal app.name, session[:application].name
    
    # But salt and password are not
    assert_nil session[:application].salt
    assert_nil session[:application].password
  end
  
  test "edit app succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'})
    
    get :update_application, {:application => {:max_tries => 1, :password => '', :password_confirmation => ''}}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    
    # The app was changed
    apps = Application.all
    assert_equal 1, apps.length
    
    app = apps[0]
    assert_equal 1, app.max_tries
    assert(app.authenticate('app_pass'))
    
    # The session's app was changed
    assert_equal 1, session[:application].max_tries
  end
  
  test "edit app change password succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'})
    
    get :update_application, {:application => {:max_tries => 3, :password => 'new_pass', :password_confirmation => 'new_pass'}}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    
    # The app was changed
    apps = Application.all
    assert_equal 1, apps.length
    
    app = apps[0]
    assert(app.authenticate('new_pass'))
  end
  
  test "edit app fails with max tries" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'})
    
    get :update_application, {:application => {:max_tries => 'foo', :password => '', :password_confirmation => ''}}, {:application => app}
    
    assert_redirected_to(:controller => 'home', :action => 'edit_application')
    assert_equal 'Max tries is not a number', flash[:notice]
  end
  
  test "home" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :home, {}, {:application => app}
  
    assert_template 'home/home.html.erb'
  end
  
  test "login fails wrong name" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :login, :application => {:name => 'wrong_app', :password => 'app_pass'}
    
    assert_redirected_to(:controller => 'home', :action => 'index')
    assert_equal 'Invalid name/password', flash[:notice]
  end
  
  test "login fails wrong pass" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :login, :application => {:name => 'app', :password => 'wrong_pass'}
    
    assert_redirected_to(:controller => 'home', :action => 'index')
    assert_equal 'Invalid name/password', flash[:notice]
  end
  
  test "create app fails name already exists" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :create_application, :new_application => {:name => 'app', :password => 'foo'}
    
    assert_redirected_to(:controller => 'home', :action => 'index')
    assert_equal 'Name has already been taken', flash[:new_notice]
  end
  
  test "create app fails name is empty" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :create_application, :new_application => {:name => '   ', :password=> 'foo'}
    
    assert_redirected_to(:controller => 'home', :action => 'index')
    assert_equal "Name can't be blank", flash[:new_notice]
  end
  
  test "create app fails password is empty" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :create_application, :new_application => {:name => 'new_app', :password => '   '}
    
    assert_redirected_to(:controller => 'home', :action => 'index')
    assert_equal "Password can't be blank", flash[:new_notice]
  end
  
  test "create app fails password confirmation is wrong" do
    app = Application.create({:name => 'app', :password => 'app_pass', :password_confirmation => 'app_pass'});
    
    get :create_application, :new_application => {:name => 'new_app', :password => 'foopass', :password_confirmation => 'foopass2'}
    
    assert_redirected_to(:controller => 'home', :action => 'index')
    assert_equal "Password doesn't match confirmation", flash[:new_notice]
  end
end
