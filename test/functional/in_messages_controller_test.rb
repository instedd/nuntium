require 'test_helper'

class InMessagesControllerTest < ActionController::TestCase
  test "should convert one message to rss item" do
    create_first_message
  
    get :index
    
    assert_select "title", "Inbox"
    
    assert_select "description", "Body of the message"
    assert_select "author", "Someone"
    assert_select "guid", "someguid"
    assert_select "pubDate", "Tue, 03 Jun 2003 09:39:21 +0000"
  end
  
  test "should convert two messages to rss items ordered by timestamp" do
    create_first_message
    create_second_message
  
    get :index
    
    assert_select "title", "Inbox"
    
    assert_select "pubDate" do |es|
      assert_equal 2, es.length
      assert_select es[0], "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
      assert_select es[1], "pubDate", "Tue, 03 Jun 2003 09:39:21 +0000"
    end
  end
  
  test "should return not modified for If-Modified-Since" do
    create_first_message
    create_second_message
  
    @request.env["If-Modified-Since"] = "Thu, 03 Jun 2004 09:39:21 GMT"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply If-Modified-Since" do
    create_first_message
    create_second_message
  
    @request.env["If-Modified-Since"] = "Tue, 03 Jun 2003 09:39:21 GMT"
    get :index
    
    assert_select "title", "Inbox"
    
    assert_select "description", "Body of the message 2"
    assert_select "author", "Someone 2"
    assert_select "guid", "someguid 2"
    assert_select "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
  end
  
  test "should return not modified for ETag" do
    create_first_message
    create_second_message
  
    @request.env["ETag"] = "someguid 2"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply ETag" do
    create_first_message
    create_second_message
  
    @request.env["ETag"] = "someguid"
    get :index
    
    assert_select "title", "Inbox"
    
    assert_select "description", "Body of the message 2"
    assert_select "author", "Someone 2"
    assert_select "guid", "someguid 2"
    assert_select "pubDate", "Thu, 03 Jun 2004 09:39:21 +0000"
  end
  
  # Utility methods follow
  
  def create_first_message
    msg = InMessage.new
    msg.body = "Body of the message"
    msg.from = "Someone"
    msg.guid = "someguid"
    msg.timestamp = Time.parse("Tue, 03 Jun 2003 09:39:21 GMT")
    msg.save
  end
  
  def create_second_message
    msg = InMessage.new
    msg.body = "Body of the message 2"
    msg.from = "Someone 2"
    msg.guid = "someguid 2"
    msg.timestamp = Time.parse("Thu, 03 Jun 2004 09:39:21 GMT")
    msg.save
  end
  
end
