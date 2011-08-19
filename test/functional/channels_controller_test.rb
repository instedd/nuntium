require 'test_helper'

class ChannelsControllerTest < ActionController::TestCase

  def setup
    @account = Account.make
  end

  test "create qst server channel succeeds" do
    attrs = Channel.plan :qst_server

    post :create, {:kind => 'qst_server', :channel => attrs}, {:account_id => @account.id}

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{attrs[:name]} was created", flash[:notice]

    # The channel was created
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

    put :update, {:id => chan.id, :channel => {:protocol => 'sms', :direction => Channel::Bidirectional, :configuration => {:password => 'new_pass', :password_confirmation => 'new_pass'}}}, {:account_id => @account.id}

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{chan.name} was updated", flash[:notice]

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

    put :update, {:id => chan.id, :channel => {:protocol => 'mail', :priority => 200, :application_id => app2.id, :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}}, {:account_id => @account.id}

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{chan.name} was updated", flash[:notice]

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

    delete :destroy, {:id => chan.id}, {:account_id => @account.id}

    # Go to channels page
    assert_redirected_to channels_path
    assert_equal "Channel #{chan.name} was deleted", flash[:notice]

    # The channel was deleted
    chans = Channel.all
    assert_equal 0, chans.length
  end

  test "edit channel fails protocol empty" do
    chan = Channel.make :qst_server, :account => @account

    put :update, {:id => chan.id, :channel => {:protocol => '', :direction => Channel::Bidirectional, :configuration => {:password => '', :password_confirmation => ''}}}, {:account_id => @account.id}

    assert_template "channels/edit"
  end

  test "enable channel" do
    chan = Channel.make :qst_server, :account => @account, :enabled => false

    get :enable, {:id => chan.id}, {:account_id => @account.id}

    # Go to channels page
    assert_response :ok
    assert_equal "Channel #{chan.name} was enabled", @response.body

    # The channel was enabled
    chans = Channel.all
    assert_true chans[0].enabled
  end

  test "disable channel re-routes" do
    chan1 = Channel.make :qst_server, :account => @account
    chan2 = Channel.make :qst_server, :account => @account

    app = Application.make :account => @account
    msg = AOMessage.make :account => @account, :application => app, :channel => chan1, :state => 'queued'

    get :disable, {:id => chan1.id}, {:account_id => @account.id}

    chan1.reload
    chan2.reload
    msg.reload

    assert_false chan1.enabled
    assert_true chan2.enabled
    assert_equal chan2.id, msg.channel_id
  end

  test "pause channel" do
    chan = Channel.make :qst_server, :account => @account

    get :pause, {:id => chan.id}, {:account_id => @account.id}

    assert_response :ok
    assert_equal "Channel #{chan.name} was paused", @response.body

    # The channel was paused
    chans = Channel.all
    assert_true chans[0].paused
  end

  test "resume channel" do
    chan = Channel.make :qst_server, :account => @account, :paused => true

    get :resume, {:id => chan.id}, {:account_id => @account.id}

    # Go to channels page
    assert_response :ok
    assert_equal "Channel #{chan.name} was resumed", @response.body

    # The channel was resumed
    chans = Channel.all
    assert_false chans[0].paused
  end
end
