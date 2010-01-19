require 'test_helper'

class ChannelControllerTest < ActionController::TestCase

  test "create qst server channel succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    
    get :create_channel, {:kind => 'qst_server', :channel => {:name => 'chan', :protocol => 'sms', :configuration => {:password => 'chan_pass', :password_confirmation => 'chan_pass'}}}, {:application_id => app.id}
    
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
    assert_equal 'qst_server', chan.kind
    assert(chan.handler.authenticate('chan_pass'))
  end
  
  test "edit channel change password succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.new({:application_id => app.id, :name => 'chan', :protocol => 'sms', :direction => Channel::Both, :kind => 'qst_server'})
    chan.configuration = {:password => 'chan_pass'}
    chan.save
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'sms', :configuration => {:password => 'new_pass', :password_confirmation => 'new_pass'}}}, {:application_id => app.id}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was updated', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    assert(chan.handler.authenticate('new_pass'))
  end
  
  test "edit qst server channel succeeds" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.new({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst_server'})
    chan.configuration = {:password => 'chan_pass'}
    chan.save
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'mail', :configuration => {:password => '', :password_confirmation => ''}}}, {:application_id => app.id}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was updated', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    
    assert_equal 'mail', chan.protocol
    assert(chan.handler.authenticate('chan_pass'))
  end
  
  test "delete channel" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.new({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst_server'})
    chan.configuration = {:password => 'chan_pass'}
    chan.save
    
    get :delete_channel, {:id => chan.id}, {:application_id => app.id}
    
    # Go to app home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was deleted', flash[:notice]
    
    # The channel was deleted
    chans = Channel.all
    assert_equal 0, chans.length
  end
  
  # ------------------------ #
  # Validations tests follow #
  # ------------------------ #
  
  test "edit channel fails protocol empty" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.new({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst_server'})
    chan.configuration = {:password => 'chan_pass'}
    chan.save
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => '', :configuration => {:password => '', :password_confirmation => ''}}}, {:application_id => app.id}
    assert_redirected_to(:controller => 'channel', :action => 'edit_channel')
  end

  test "create chan fails name already exists" do
    app = Application.create({:name => 'app', :password => 'app_pass'})
    chan = Channel.new({:application_id => app.id, :name => 'chan', :protocol => 'sms', :kind => 'qst_server'})
    chan.configuration = {:password => 'chan_pass'}
    chan.save
    
    get :create_channel, {:kind => 'qst_server', :channel => {:name => 'chan', :protocol => 'sms', :configuration => {:password => 'chan_pass', :password_confirmation => 'chan_pass'}}}, {:application_id => app.id}
    assert_redirected_to(:controller => 'channel', :action => 'new_channel')
  end
  

end
