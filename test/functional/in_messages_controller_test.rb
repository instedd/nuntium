require 'test_helper'

class InMessagesControllerTest < ActionController::TestCase
  test "should convert one in message to rss item" do
    msg = InMessage.new  
    msg.body = "Body of the message"
    msg.from = "Someone"
    msg.guid = "someguid"
    msg.save
  
    get :index
    
    assert_select "title", "Inbox"
    
    assert_select "description", "Body of the message"
    assert_select "author", "Someone"
    assert_select "guid", "someguid"
  end
end
