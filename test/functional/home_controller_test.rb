require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "login succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'});
    
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
    app = Application.create({:name => 'app', :password => 'app_pass'})
    
    get :update_application, {:application => {:max_tries => 1, :password => '', :password_confirmation => ''}}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Application was changed', flash[:notice]
    
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
    app = Application.create({:name => 'app', :password => 'app_pass'})
    
    get :update_application, {:application => {:max_tries => 3, :password => 'new_pass', :password_confirmation => 'new_pass'}}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Application was changed', flash[:notice]
    
    # The app was changed
    apps = Application.all
    assert_equal 1, apps.length
    
    app = apps[0]
    assert(app.authenticate('new_pass'))
  end
  
  test "edit qst channel succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.create({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst', :configuration => {:password => 'chan_pass'}})
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'mail', :configuration => {:password => '', :password_confirmation => ''}}}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was changed', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    
    assert_equal 'mail', chan.protocol
    assert(chan.handler.authenticate('chan_pass'))
  end
  
  test "edit channel change password succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.create({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst', :configuration => {:password => 'chan_pass'}})
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'sms', :configuration => {:password => 'new_pass', :password_confirmation => 'new_pass'}}}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was changed', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    assert(chan.handler.authenticate('new_pass'))
  end
  
  test "create qst channel succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    
    get :create_channel, {:kind => 'qst', :channel => {:name => 'chan', :protocol => 'sms', :configuration => {:password => 'chan_pass', :password_confirmation => 'chan_pass'}}}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was created', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    assert_equal app.id, chan.application_id
    assert_equal 'chan', chan.name
    assert_equal 'sms', chan.protocol
    assert_equal 'qst', chan.kind
    assert(chan.handler.authenticate('chan_pass'))
  end
  
  test "delete channel" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.create({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst', :configuration => {:password => 'chan_pass'}})
    
    get :delete_channel, {:id => chan.id}, {:application => app}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was deleted', flash[:notice]
    
    # The channel was deleted
    chans = Channel.all
    assert_equal 0, chans.length
  end
  
  test "home" do
    app = Application.create({:name => 'app', :password => 'app_pass'});
    get :home, {}, {:application => app}
    assert_template 'home/home.html.erb'
  end
  
  # ------------------------ #
  # Validations tests follow #
  # ------------------------ #
  
  test "edit channel fails protocol empty" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.create({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst', :configuration => {:password => 'chan_pass'}})
    get :update_channel, {:id => chan.id, :channel => {:protocol => '', :configuration => {:password => '', :password_confirmation => ''}}}, {:application => app}
    assert_redirected_to(:controller => 'home', :action => 'edit_channel')
  end
  
  test "edit app fails with max tries" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    get :update_application, {:application => {:max_tries => 'foo', :password => '', :password_confirmation => ''}}, {:application => app}
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
  
  test "create chan fails name already exists" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.create({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst', :configuration => {:password => 'chan_pass'}})
    get :create_channel, {:kind => 'qst', :channel => {:name => 'chan', :protocol => 'sms', :configuration => {:password => 'chan_pass', :password_confirmation => 'chan_pass'}}}, {:application => app}
    assert_redirected_to(:controller => 'home', :action => 'new_channel')
  end
  
end
