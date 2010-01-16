require 'test_helper'
require 'base64'
require 'digest/md5'
require 'yaml'

class RssControllerTest < ActionController::TestCase
  test "should convert one rss item to out message" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_equal app.id, msg.application_id
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
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].id
    assert_equal chan.id, unread[0].channel_id
  end
  
  test "should select channel based on protocol case qst" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst', 'protocol1')
    chan2 = create_channel(app, 'chan2', 'chan_pass2', 'qst', 'protocol2');
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol2://Someone else')
    post :create
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_equal chan2.id, unread[0].channel_id
  end
  
  test "should create clickatell job" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :incoming_password => 'incoming' }
    chan.save
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create
    
    msg = AOMessage.first
    
    jobs = Delayed::Job.all
    assert_equal 1, jobs.length
    
    job = jobs[0]
    job = YAML::load job.handler
    assert_equal 'SendClickatellMessageJob', job.class.to_s
    assert_equal app.id, job.application_id
    assert_equal chan.id, job.channel_id
    assert_equal msg.id, job.message_id
  end
  
  test "should create smtp job" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'smtp', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:host => 'host', :port => 430, :user => 'user', :password => 'password' }
    chan.save
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create
    
    msg = AOMessage.first
    
    jobs = Delayed::Job.all
    assert_equal 1, jobs.length
    
    job = jobs[0]
    job = YAML::load job.handler
    assert_equal 'SendSmtpMessageJob', job.class.to_s
    assert_equal app.id, job.application_id
    assert_equal chan.id, job.channel_id
    assert_equal msg.id, job.message_id
  end
  
  test "qst no protocol in message" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('Someone else')
    post :create
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'error', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 0, unread.length
    
    logs = ApplicationLog.all
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal app.id, log.application_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "Protocol not found in 'to' field", log.message
  end
  
  test "qst channel not found for protocol" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('unknown://Someone else')
    post :create
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'error', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 0, unread.length
    
    logs = ApplicationLog.all
    assert_equal 2, logs.length
    log = logs[1]
    assert_equal app.id, log.application_id
    assert_equal messages[0].id, log.ao_message_id
    assert_equal "No channel found for protocol 'unknown'", log.message
  end
  
  test "qst more than one channel found for protocol" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    chan2 = create_channel(app, 'chan2', 'chan_pass', 'qst')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = new_rss_feed('protocol://Someone else')
    post :create
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    assert_equal 'queued', messages[0].state
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_true unread[0].channel_id == chan.id || unread[0].channel_id == chan2.id
  end
  
  test "should convert one message to rss item" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    msg = new_at_message(app, 0)
    
    app2, chan2 = create_app_and_channel('app2', 'app_pass2', 'chan2', 'chan_pass2', 'qst')
    new_at_message(app2, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    get :index
    
    assert_equal msg.timestamp, @response.last_modified
    
    assert_select "title", "Outbox"
    assert_select "lastBuildDate", msg.timestamp.rfc822
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end

    assert_shows_message_as_rss_item msg
  end
  
  test "should convert one message without subject to rss item" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    msg = new_at_message(app, 0)
    msg.subject = nil
    msg.save
    
    app2, chan2 = create_app_and_channel('app2', 'app_pass2', 'chan2', 'chan_pass2', 'qst')
    new_at_message(app2, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end

    assert_shows_message_as_rss_item msg
  end
  
  test "should convert two messages to rss items ordered by timestamp" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "pubDate" do |es|
      assert_equal 2, es.length
      assert_select es[0], "pubDate", 'Sun, 02 Jan 2000 05:00:00 +0000'
      assert_select es[1], "pubDate", 'Mon, 03 Jan 2000 05:00:00 +0000'
    end
  end
  
  test "should return not modified for HTTP_IF_MODIFIED_SINCE" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(1).to_s
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    new_at_message(app, 0)
    msg = new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(0).to_s
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_shows_message_as_rss_item msg
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE and increment tries" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    msg_0 = new_at_message(app, 0)
    msg_1 = new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(0).to_s
    
    # 1st try
    get :index
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 1, msgs[1].tries
    assert_equal 'delivered', msgs[1].state
    
    # 2st try
    get :index
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 2, msgs[1].tries
    assert_equal 'delivered', msgs[1].state
    
    # 3rd try
    get :index
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 3, msgs[1].tries
    assert_equal 'delivered', msgs[1].state
    
    # 4th try: no message return and it's status is failed
    get :index
    
    assert_select "guid", {:count => 0}
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 4, msgs[1].tries
    assert_equal 'failed', msgs[1].state 
    
    # 5th try: tries was not incremented
    get :index
    
    assert_select "guid", {:count => 0}
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    assert_equal 0, msgs[0].tries
    assert_equal 4, msgs[1].tries
    assert_equal 'failed', msgs[1].state 
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 1"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    new_at_message(app, 0)
    msg = new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_shows_message_as_rss_item msg
  end
  
  test "create not authorized" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'wrong_pass')
    post :create
    
    assert_response 401
  end
  
  test "index not authorized" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'wrong_pass')
    get :index
    
    assert_response 401
  end
  
  test "index not authorized wrong interface" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst')
    app.update_attribute :interface, 'qst'
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    get :index
    
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
