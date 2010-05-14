require 'test_helper'
require 'base64'
require 'digest/md5'
require 'yaml'

class RssControllerTest < ActionController::TestCase
  def setup
    @account, @chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    @application = create_app @account
  end
  
  def create(to)
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed(to)
    post :create, :account_name => @account.name, :application_name => @application.name
    assert_response :ok
  end

  test "should convert one rss item to out message" do
    create 'protocol://Someone else'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_equal @account.id, msg.account_id
    assert_equal @application.id, msg.application_id
    assert_equal "First message", msg.subject
    assert_equal "Body of the message", msg.body
    assert_equal "Someone", msg.from
    assert_equal "protocol://Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal time_for_msg(0) , msg.timestamp
    assert_equal 'queued', msg.state
    assert_equal @chan.id, msg.channel_id
  end
  
  test "should create qst outgoing message" do
    create 'protocol://Someone else'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_equal @chan.id, unread[0].channel_id
  end
  
  test "should select channel based on protocol case qst server" do
    chan2 = create_channel(@account, 'chan2', 'chan_pass2', 'qst_server', 'protocol2');
  
    create 'protocol2://Someone else'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_equal chan2.id, unread[0].channel_id
  end
  
  test "qst server no protocol in message" do
    create 'Someone else'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 0, unread.length
    
    logs = AccountLog.all
    
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal @account.id, log.account_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "Protocol not found in 'to' field", log.message
  end
  
  test "qst server channel not found for protocol" do
    create 'unknown://Someone else'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'failed', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 0, unread.length
    
    logs = AccountLog.all
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal @account.id, log.account_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "No channel found for protocol 'unknown'", log.message
  end
  
  test "qst server more than one channel found for protocol" do
    chan2 = create_channel(@account, 'chan2', 'chan_pass', 'qst_server')
  
    create 'protocol://Someone else'
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'queued', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_true unread[0].channel_id == @chan.id || unread[0].channel_id == chan2.id
  end
  
  test "should convert one message to rss item" do
    application2 = create_app @account, 2
    
    msg = new_at_message(@application, 0)
    new_at_message(application2, 1)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
    
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
    msg = new_at_message(@application, 0)
    msg.subject = nil
    msg.save!
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end

    assert_shows_message_as_rss_item msg
  end
  
  test "should convert two messages to rss items ordered by timestamp" do
    new_at_message(@application, 0)
    new_at_message(@application, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')  
    get :index, :account_name => @account.name, :application_name => @application.name
    
    assert_select "title", "Outbox"
    
    assert_select "pubDate" do |es|
      assert_equal 2, es.length
      assert_select es[0], "pubDate", 'Sun, 02 Jan 2000 05:00:00 +0000'
      assert_select es[1], "pubDate", 'Mon, 03 Jan 2000 05:00:00 +0000'
    end
  end
  
  test "should return not modified for HTTP_IF_MODIFIED_SINCE" do
    new_at_message(@application, 0)
    new_at_message(@application, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(1).to_s
    get :index, :account_name => @account.name, :application_name => @application.name
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE" do
    new_at_message(@application, 0)
    msg = new_at_message(@application, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(0).to_s
    get :index, :account_name => @account.name, :application_name => @application.name
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_shows_message_as_rss_item msg
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE and increment tries" do
    msg_0 = new_at_message(@application, 0)
    msg_1 = new_at_message(@application, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(0).to_s
    
    1.upto 5 do |try|
      get :index, :account_name => @account.name, :application_name => @application.name
      
      msgs = ATMessage.all
      assert_equal 2, msgs.length
      assert_equal 0, msgs[0].tries
      
      if 1 <= try and try <= 3
        assert_select "guid" do |es|
          assert_equal 1, es.length
        end 
        assert_equal try, msgs[1].tries
        assert_equal 'delivered', msgs[1].state
      else
        assert_select "guid", {:count => 0}
        assert_equal 4, msgs[1].tries
        assert_equal 'failed', msgs[1].state
      end
    end
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    new_at_message(@application, 0)
    new_at_message(@application, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 1"
    get :index, :account_name => @account.name, :application_name => @application.name
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    new_at_message(@application, 0)
    msg = new_at_message(@application, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get :index, :account_name => @account.name, :application_name => @application.name
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_shows_message_as_rss_item msg
  end
  
  test "create not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'wrong_pass')
    post :create, :account_name => @account.name, :application_name => @application.name
    assert_response 401
  end
  
  test "index not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'wrong_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
    assert_response 401
  end
  
  test "index not found name mismatch 1" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("account2/#{@application.name}", 'app_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
    assert_response 401
  end
  
  test "index not found name mismatch 2" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/application2", 'app_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
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
