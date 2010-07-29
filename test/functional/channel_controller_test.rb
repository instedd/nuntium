require 'test_helper'

class ChannelControllerTest < ActionController::TestCase

  def setup
    @account = Account.make
  end

  test "create qst server channel succeeds" do
    attrs = Channel.plan :qst_server
  
    get :create_channel, {:kind => 'qst_server', :channel => attrs}, {:account_id => @account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was created', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    assert_equal @account.id, chan.account_id
    assert_equal attrs[:name], chan.name
    assert_equal attrs[:protocol], chan.protocol
    assert_equal attrs[:kind], chan.kind
    assert(chan.handler.authenticate(attrs[:configuration][:password]))
  end
  
  test "edit channel change password succeeds" do
    chan = Channel.make :qst_server, :account => @account
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'sms', :direction => Channel::Bidirectional, :configuration => {:password => 'new_pass', :password_confirmation => 'new_pass'}}}, {:account_id => @account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was updated', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]
    assert(chan.handler.authenticate('new_pass'))
  end
  
  test "edit qst server channel succeeds" do
    app1 = Application.make :account => @account
    app2 = Application.make :account => @account
    chan = Channel.make_unsaved :qst_server, :account => @account, :priority => 100, :application_id => app1.id
    chan.configuration[:password] = 'chan_pass'
    chan.configuration[:password_confirmation] = 'chan_pass'
    chan.configuration.delete :salt
    chan.save!
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => 'mail', :priority => 200, :application_id => app2.id, :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}}, {:account_id => @account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was updated', flash[:notice]
    
    # The channel was changed
    chans = Channel.all
    assert_equal 1, chans.length
    
    chan = chans[0]
    
    assert_equal 'mail', chan.protocol
    assert_equal 200, chan.priority
    assert_equal app2.id, chan.application_id
    assert(chan.handler.authenticate('chan_pass'))
  end
  
  test "delete channel" do
    chan = Channel.make :qst_server, :account => @account
    
    get :delete_channel, {:id => chan.id}, {:account_id => @account.id}
    
    # Go to account home page
    assert_redirected_to(:controller => 'home', :action => 'home')
    assert_equal 'Channel was deleted', flash[:notice]
    
    # The channel was deleted
    chans = Channel.all
    assert_equal 0, chans.length
  end
  
  test "edit channel fails protocol empty" do
    chan = Channel.make :qst_server, :account => @account
    
    get :update_channel, {:id => chan.id, :channel => {:protocol => '', :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}}, {:account_id => @account.id}
    
    assert_template "channel/edit_qst_server_channel.html.erb"
  end
  
  test "disable channel re-routes" do
    chan1 = Channel.make :qst_server, :account => @account
    chan2 = Channel.make :qst_server, :account => @account
    
    app = Application.make :account => @account
    msg = AOMessage.make :account => @account, :application => app, :channel => chan1, :state => 'queued'
    
    get :disable_channel, {:id => chan1.id}, {:account_id => @account.id}
    
    chan1.reload
    chan2.reload
    msg.reload
    
    assert_false chan1.enabled
    assert_true chan2.enabled
    assert_equal chan2.id, msg.channel_id
  end

end
