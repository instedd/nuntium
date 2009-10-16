require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  test "get one" do
    create_message(0)
    create_unread_message(0)
  
    get :index
    
    assert_select "message[id=?]", "someguid 0"
    assert_select "message[from=?]", "Someone 0"
    assert_select "message[to=?]", "Someone else 0"
    assert_select "message[when=?]", "Tue, 03 Jun 2003 09:39:21 +0000"
    assert_select "message text", "Body of the message 0"
    
    unread = UnreadOutMessage.all    
    assert_equal 1, unread.length
    assert_equal "someguid 0", unread[0].guid
  end
  
  test "get one not unread" do
    create_message(0)
  
    get :index
    assert_response :not_modified
  end
  
  test "should return not modified for If-None-Match" do
    create_message(0)
    create_unread_message(0)
    
    create_message(1)
    create_unread_message(1)
  
    @request.env["If-None-Match"] = "someguid 1"
    get :index
    
    assert_response :not_modified
    
    assert_equal 0, UnreadOutMessage.all.length
  end
  
  test "should apply If-None-Match" do
    create_message(0)
    create_unread_message(0)
    
    create_message(1)
    create_unread_message(1)
  
    @request.env["If-None-Match"] = "someguid 0"
    get :index
    
    assert_select "message" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "message[id=?]", "someguid 1"
    assert_select "message[from=?]", "Someone 1"
    assert_select "message[to=?]", "Someone else 1"
    assert_select "message[when=?]", "Thu, 03 Jun 2004 09:39:21 +0000"
    assert_select "message text", "Body of the message 1"
    
    unread = UnreadOutMessage.all
    assert_equal 1, unread.length
    assert_equal "someguid 1", unread[0].guid
  end
  
  test "should apply If-None-Match with max" do
    (1..4).each do |i| 
      create_message(i)
      create_unread_message(i)
    end
  
    @request.env["If-None-Match"] = "someguid 2"
    get :index, :max => 1
    
    assert_select "message" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "message[id=?]", "someguid 3"
    assert_select "message[from=?]", "Someone 3"
    assert_select "message[to=?]", "Someone else 3"
    assert_select "message[when=?]", "Sat, 03 Jun 2006 09:39:21 +0000"
    assert_select "message text", "Body of the message 3"
    
    unread = UnreadOutMessage.all
    assert_equal 2, unread.length
    assert_equal "someguid 3", unread[0].guid
    assert_equal "someguid 4", unread[1].guid
  end

  # Utility methods follow
  
  def create_message(i)
    msg = OutMessage.new
    msg.body = "Body of the message #{i}"
    msg.from = "Someone #{i}"
    msg.to = "Someone else #{i}"
    msg.guid = "someguid #{i}"
    msg.timestamp = Time.parse("03 Jun #{2003+i} 09:39:21 GMT")
    msg.save
  end
  
  def create_unread_message(i)
    msg = UnreadOutMessage.new
    msg.guid = "someguid #{i}"
    msg.save
  end
  
end
