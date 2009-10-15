require 'test_helper'

class InMessagesControllerTest < ActionController::TestCase
  test "should convert one in message to rss item" do
    msg = InMessage.new  
    msg.body = "Body of the message"
    msg.from = "Someone"
    msg.guid = "someguid"
    msg.timestamp = Time.parse("Tue, 03 Jun 2003 09:39:21 GMT")
    msg.save
  
    get :index
    
    assert_select "title", "Inbox"
    
    assert_select "description", "Body of the message"
    assert_select "author", "Someone"
    assert_select "guid", "someguid"
    assert_select "pubDate", "Tue, 03 Jun 2003 09:39:21 +0000"
  end
end
