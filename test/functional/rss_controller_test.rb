require 'test_helper'
require 'base64'
require 'digest/md5'
require 'yaml'

class RssControllerTest < ActionController::TestCase
  def setup
    @request.env['CONTENT_TYPE'] = 'application/xml'
  end

  test "should convert one rss item to out message" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application = create_app account
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create, :account_name => account.name, :application_name => 'application'
    
    assert_response :ok
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_equal account.id, msg.account_id
    assert_equal application.id, msg.application_id
    assert_equal "First message", msg.subject
    assert_equal "Body of the message", msg.body
    assert_equal "Someone", msg.from
    assert_equal "protocol://Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal time_for_msg(0) , msg.timestamp
    assert_equal 'queued', msg.state
    assert_equal chan.id, msg.channel_id
  end
  
  test "should create qst outgoing message" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application = create_app account
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create, :account_name => account.name, :application_name => 'application'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_equal chan.id, unread[0].channel_id
  end
  
  test "should select channel based on protocol case qst server" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server', 'protocol1')
    application = create_app account
    chan2 = create_channel(account, 'chan2', 'chan_pass2', 'qst_server', 'protocol2');
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol2://Someone else')
    post :create, :account_name => account.name, :application_name => 'application'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_equal chan2.id, unread[0].channel_id
  end
  
  test "qst server no protocol in message" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application = create_app account
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('Someone else')
    post :create, :account_name => account.name, :application_name => 'application'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 0, unread.length
    
    logs = AccountLog.all
    
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal account.id, log.account_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "Protocol not found in 'to' field", log.message
  end
  
  test "qst server channel not found for protocol" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application = create_app account
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('unknown://Someone else')
    post :create, :account_name => account.name, :application_name => 'application'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 0, unread.length
    
    logs = AccountLog.all
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal account.id, log.account_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "No channel found for protocol 'unknown'", log.message
  end
  
  test "qst server more than one channel found for protocol" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    chan2 = create_channel(account, 'chan2', 'chan_pass', 'qst_server')
  
    application = create_app account
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application', 'app_pass')  
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create, :account_name => account.name, :application_name => 'application'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'queued', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_true unread[0].channel_id == chan.id || unread[0].channel_id == chan2.id
  end
  
  test "should convert one message to rss item" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    application2 = create_app account, 2
    
    msg = new_at_message(application1, 0)
    new_at_message(application2, 1)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_response :ok
    
    assert_equal msg.timestamp, @response.last_modified
    
    assert_select "title", "Outbox"
    assert_select "lastBuildDate", msg.timestamp.rfc822
    
    assert_select "guid", :count => 1 do |es|
      assert_equal 1, es.length
    end

    assert_shows_message_as_rss_item msg
  end
  
  test "should convert one message without subject to rss item" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    
    msg = new_at_message(application1, 0)
    msg.subject = nil
    msg.save!
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end

    assert_shows_message_as_rss_item msg
  end
  
  test "should convert two messages to rss items ordered by timestamp" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    
    new_at_message(application1, 0)
    new_at_message(application1, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')  
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "title", "Outbox"
    
    assert_select "pubDate" do |es|
      assert_equal 2, es.length
      assert_select es[0], "pubDate", 'Sun, 02 Jan 2000 05:00:00 +0000'
      assert_select es[1], "pubDate", 'Mon, 03 Jan 2000 05:00:00 +0000'
    end
  end
  
  test "should return not modified for HTTP_IF_MODIFIED_SINCE" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    
    new_at_message(application1, 0)
    new_at_message(application1, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(1).to_s
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    
    new_at_message(application1, 0)
    msg = new_at_message(application1, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(0).to_s
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_shows_message_as_rss_item msg
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE and increment tries" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    
    msg_0 = new_at_message(application1, 0)
    msg_1 = new_at_message(application1, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(0).to_s
    
    # 1st try
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 1, msgs[1].tries
    assert_equal 'delivered', msgs[1].state
    
    # 2st tryapplication1 = create_app account, 1
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 2, msgs[1].tries
    assert_equal 'delivered', msgs[1].state
    
    # 3rd try
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 3, msgs[1].tries
    assert_equal 'delivered', msgs[1].state
    
    # 4th try: no message return and it's status is failed
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "guid", {:count => 0}
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 4, msgs[1].tries
    assert_equal 'failed', msgs[1].state 
    
    # 5th try: tries was not incremented
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "guid", {:count => 0}
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 4, msgs[1].tries
    assert_equal 'failed', msgs[1].state 
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    
    new_at_message(application1, 0)
    new_at_message(application1, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 1"
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
    
    new_at_message(application1, 0)
    msg = new_at_message(application1, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_shows_message_as_rss_item msg
  end
  
  test "create not authorized" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'wrong_pass')
    post :create, :account_name => account.name, :application_name => 'application1'
    
    assert_response 401
  end
  
  test "index not authorized" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application1', 'wrong_pass')
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_response 401
  end
  
  test "index not found name mismatch 1" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account2/application1', 'app_pass')
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_response 401
  end
  
  test "index not found name mismatch 2" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    application1 = create_app account, 1
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('account/application2', 'app_pass')
    get :index, :account_name => account.name, :application_name => 'application1'
    
    assert_response 401
  end
  
  # Utility methods follow
  def new_rss_feed(to)
    <<-eos
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>First message</title>
            <description>Body of the message</description>
            <author>Someone</author>
            <to>#{to}</to>
            <pubDate>Sun Jan 02 05:00:00 UTC 2000</pubDate>
            <guid>someguid</guid>
          </item>
        </channel>
      </rss>
    eos
  end
  
end
