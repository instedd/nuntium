require 'test_helper'

class ChannelControllerTest < ActionController::TestCase

  test "create qst server channel succeeds" do
    account = Account.create!({:name => 'account', :password => 'account_pass'})
    
    get :create_channel, {:kind => 'qst_server', :channel => {:name => 'chan', :protocol => 'sms', :direction => Channel::Bidirectional, :configuration => {:password => 'chan_pass', :password_confirmation => 'chan_pass'}}}, {:account_id => account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was created', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    assert_equal account.id, chan.account_id
    assert_equal 'chan', chan.name
    assert_equal 'sms', chan.protocol
    assert_equal 'qst_server', chan.kind
    assert(chan.handler.authenticate('chan_pass'))
  end
  
  test "edit channel change password succeeds" do
    account = Account.create!({:name => 'account', :password => 'account_pass'})
    chan = Channel.new({:account_id => account.id, :name => 'chan', :protocol => 'sms', :direction => Channel::Bidirectional, :kind => 'qst_server'})
    chan.configuration = {:password => 'chan_pass'}
    chan.save!
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'sms', :direction => Channel::Bidirectional, :configuration => {:password => 'new_pass', :password_confirmation => 'new_pass'}}}, {:account_id => account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was updated', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    "channel/edit_qst_server_channel.html.erb"
    chan = chans[0]
    assert(chan.handler.authenticate('new_pass'))
  end
  
  test "edit qst server channel succeeds" do
    account = Account.create!({:name => 'account', :password => 'account_pass'})
    chan = Channel.new({:account_id => account.id, :name => 'chan', :direction => Channel::Bidirectional, :protocol => 'sms', :kind => 'qst_server'})
    chan.configuration = {:password => 'chan_pass'}
    chan.save!
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'mail', :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}}, {:account_id => account.id}
    
    # Go to account home page
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
    account = Account.create!({:name => 'account', :password => 'account_pass'})
    chan = Channel.new({:account_id => account.id, :name => 'chan', :protocol => 'sms', :kind => 'qst_server', :direction => Channel::Bidirectional})
    chan.configuration = {:password => 'chan_pass'}
    chan.save!
    
    get :delete_channel, {:id => chan.id}, {:account_id => account.id}
    
    # Go to account home page
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
    account = Account.create!({:name => 'account', :password => 'account_pass'})
    chan = Channel.new({:account_id => account.id, :name => 'chan', :protocol => 'sms', :kind => 'qst_server', :direction => Channel::Bidirectional})
    chan.configuration = {:password => 'chan_pass'}
    chan.save!
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => '', :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}}, {:account_id => account.id}
    
    assert_template "channel/edit_qst_server_channel.html.erb"
  end

  test "create chan fails name already exists" do
    account = Account.create!({:name => 'account', :password => 'account_pass'})
    chan = Channel.new({:account_id => account.id, :name => 'chan', :protocol => 'sms', :kind => 'qst_server', :direction => Channel::Bidirectional})
    chan.configuration = {:password => 'chan_pass'}
    chan.save!
    
    get :create_channel, {:kind => 'qst_server', :channel => {:name => 'chan', :direction => Channel::Bidirectional, :protocol => 'sms', :configuration => {:password => 'chan_pass', :password_confirmation => 'chan_pass'}}}, {:account_id => account.id}
    assert_template 'new_qst_server_channel'
  end

end
