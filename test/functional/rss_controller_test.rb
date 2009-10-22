require 'test_helper'
require 'base64'
require 'digest/md5'

class RssControllerTest < ActionController::TestCase
  test "should convert one rss item to out message" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    @request.env['RAW_POST_DATA'] = <<-eos
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>First message</title>
            <description>Body of the message</description>
            <author>Someone</author>
            <to>Someone else</to>
            <pubDate>Tue, 03 Jun 2003 09:39:21 GMT</pubDate>
            <guid>someguid</guid>
          </item>
        </channel>
      </rss>
    eos
    post :create
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    assert_equal app.id, msg.application_id
    assert_equal "First message", msg.subject
    assert_equal "Body of the message", msg.body
    assert_equal "Someone", msg.from
    assert_equal "Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal Time.parse("Tue, 03 Jun 2003 09:39:21 GMT"), msg.timestamp
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal "someguid", unread[0].guid
    assert_equal chan.id, unread[0].channel_id
  end
  
  test "should convert one message to rss item" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    new_at_message(app, 0)
    
    app2, chan2 = create_app_and_channel('app2', 'app_pass2', 'chan2', 'chan_pass2')
    new_at_message(app2, 0)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "title", "Subject of the message 0"
    assert_select "description", "Body of the message 0"
    assert_select "author", "Someone 0"
    assert_select "to", "Someone else 0"
    assert_select "guid", "someguid 0"
    assert_select "pubDate", "Tue, 03 Jun 2003 09:39:21 +0000"
  end
  
  test "should convert two messages to rss items ordered by timestamp" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "pubDate" do |es|
      assert_equal 2, es.length
      assert_select es[0], "pubDate", "Tue, 03 Jun 2003 09:39:21 +0000"
      assert_select es[1], "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
    end
  end
  
  test "should return not modified for HTTP_IF_MODIFIED_SINCE" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = "Thu, 03 Jun 2004 09:39:21 GMT"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = "Tue, 03 Jun 2003 09:39:21 GMT"
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "title", "Subject of the message 1"
    assert_select "description", "Body of the message 1"
    assert_select "author", "Someone 1"
    assert_select "to", "Someone else 1"
    assert_select "guid", "someguid 1"
    assert_select "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 1"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    new_at_message(app, 0)
    new_at_message(app, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "title", "Subject of the message 1"
    assert_select "description", "Body of the message 1"
    assert_select "author", "Someone 1"
    assert_select "to", "Someone else 1"
    assert_select "guid", "someguid 1"
    assert_select "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
  end
  
  test "create not authorized" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'wrong_pass')
    post :create
    
    assert_response 401
  end
  
  test "index not authorized" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'wrong_pass')
    get :index
    
    assert_response 401
  end
  
end
