require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "login succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'});
    
    get :login, :application => {:name => 'app', :password => 'app_pass'}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    
    # App id was saved in session
    assert_equal app.id, session[:application_id]
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
    assert_equal app.id, session[:application_id]
  end
  
  test "edit app succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass', :interface => 'rss' })
    
    get :update_application, {:application => {:max_tries => 1, :interface => 'qst_client', :configuration => { :url => 'myurl' }, :password => '', :password_confirmation => ''}}, {:application_id => app.id}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Application was changed', flash[:notice]
    
    # The app was changed
    apps = Application.all
    assert_equal 1, apps.length
    
    app = apps[0]
    assert_equal 1, app.max_tries
    assert(app.authenticate('app_pass'))
  end
  
  test "edit app change password succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass', :interface => 'rss'})
    
    get :update_application, {:application => {:max_tries => 3, :interface => 'rss', :password => 'new_pass', :password_confirmation => 'new_pass'}}, {:application_id => app.id}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Application was changed', flash[:notice]
    
    # The app was changed
    apps = Application.all
    assert_equal 1, apps.length
    
    app = apps[0]
    assert(app.authenticate('new_pass'))
  end

  test "home" do
    app = Application.create({:name => 'app', :password => 'app_pass'});
    get :home, {}, {:application_id => app.id}
    assert_template 'home/home.html.erb'
  end
  
  # ------------------------ #
  # Validations tests follow #
  # ------------------------ #
  
  test "edit app fails with max tries" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    get :update_application, {:application => {:max_tries => 'foo', :password => '', :password_confirmation => ''}}, {:application_id => app.id}
    assert_redirected_to(:controller => 'home', :action => 'edit_application')
  end
  
  test "edit app fails with invalid interface" do
    app = Application.create({:name => 'app', :password => 'app_pass', :interface => 'rss'})
    get :update_application, {:application => {:max_tries => '1', :interface => 'invalid' , :password => '', :password_confirmation => ''}}, {:application_id => app.id}
    assert_redirected_to(:controller => 'home', :action => 'edit_application')
  end
  
  test "login fails wrong name" do
    app = Application.create({:name => 'app', :password => 'app_pass'});
    get :login, :application => {:name => 'wrong_app', :password => 'app_pass'}
    assert_redirected_to(:controller => 'home', :action => 'index')
  end
  
  test "login fails wrong pass" do
    app = Application.create({:name => 'app', :password => 'app_pass'});
    get :login, :application => {:name => 'app', :password => 'wrong_pass'}
    assert_redirected_to(:controller => 'home', :action => 'index')
  end
  
  test "create app fails name is empty" do
    app = Application.create({:name => 'app', :password => 'app_pass'});
    get :create_application, :new_application => {:name => '   ', :password=> 'foo'}
    assert_redirected_to(:controller => 'home', :action => 'index')
  end
  
end
