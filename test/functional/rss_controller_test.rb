require 'test_helper'

class RssControllerTest < ActionController::TestCase
  test "should convert one rss item to out message" do
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
    
    messages = OutMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    assert_equal "Body of the message", msg.body
    assert_equal "Someone", msg.from
    assert_equal "Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal Time.parse("Tue, 03 Jun 2003 09:39:21 GMT"), msg.timestamp
    
    unread = UnreadOutMessage.all
    assert_equal 1, unread.length
    assert_equal "someguid", unread[0].guid
  end

  test "should convert one message to rss item" do
    create_first_message
  
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "description", "Body of the message"
    assert_select "author", "Someone"
    assert_select "to", "Someone else"
    assert_select "guid", "someguid"
    assert_select "pubDate", "Tue, 03 Jun 2003 09:39:21 +0000"
  end
  
  test "should convert two messages to rss items ordered by timestamp" do
    create_first_message
    create_second_message
  
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "pubDate" do |es|
      assert_equal 2, es.length
      assert_select es[0], "pubDate", "Tue, 03 Jun 2003 09:39:21 +0000"
      assert_select es[1], "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
    end
  end
  
  test "should return not modified for HTTP_IF_MODIFIED_SINCE" do
    create_first_message
    create_second_message
  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = "Thu, 03 Jun 2004 09:39:21 GMT"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_MODIFIED_SINCE" do
    create_first_message
    create_second_message
  
    @request.env["HTTP_IF_MODIFIED_SINCE"] = "Tue, 03 Jun 2003 09:39:21 GMT"
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "description", "Body of the message 2"
    assert_select "author", "Someone 2"
    assert_select "to", "Someone else 2"
    assert_select "guid", "someguid 2"
    assert_select "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    create_first_message
    create_second_message
  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 2"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    create_first_message
    create_second_message
  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid"
    get :index
    
    assert_select "title", "Outbox"
    
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "description", "Body of the message 2"
    assert_select "author", "Someone 2"
    assert_select "to", "Someone else 2"
    assert_select "guid", "someguid 2"
    assert_select "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
  end
  
  # Utility methods follow
  
  def create_first_message
    msg = InMessage.new
    msg.body = "Body of the message"
    msg.from = "Someone"
    msg.to = "Someone else"
    msg.guid = "someguid"
    msg.timestamp = Time.parse("Tue, 03 Jun 2003 09:39:21 GMT")
    msg.save
  end
  
  def create_second_message
    msg = InMessage.new
    msg.body = "Body of the message 2"
    msg.from = "Someone 2"
    msg.to = "Someone else 2"
    msg.guid = "someguid 2"
    msg.timestamp = Time.parse("Thu, 03 Jun 2004 09:39:21 GMT")
    msg.save
  end
  
end
