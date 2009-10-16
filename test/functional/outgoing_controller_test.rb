require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  test "get one" do
    create_first_message
  
    get :index
    
    assert_select "message[id=?]", "someguid"
    assert_select "message[from=?]", "Someone"
    assert_select "message[to=?]", "Someone else"
    assert_select "message[when=?]", "Tue, 03 Jun 2003 09:39:21 +0000"
    assert_select "message text", "Body of the message"
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
    
    assert_select "message" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "message[id=?]", "someguid 2"
    assert_select "message[from=?]", "Someone 2"
    assert_select "message[to=?]", "Someone else 2"
    assert_select "message[when=?]", "Thu, 03 Jun 2004 09:39:21 +0000"
    assert_select "message text", "Body of the message 2"
  end
  
  test "should return not modified for If-None-Match" do
    create_first_message
    create_second_message
  
    @request.env["If-None-Match"] = "someguid 2"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply If-None-Match" do
    create_first_message
    create_second_message
  
    @request.env["If-None-Match"] = "someguid"
    get :index
    
    assert_select "message" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "message[id=?]", "someguid 2"
    assert_select "message[from=?]", "Someone 2"
    assert_select "message[to=?]", "Someone else 2"
    assert_select "message[when=?]", "Thu, 03 Jun 2004 09:39:21 +0000"
    assert_select "message text", "Body of the message 2"
  end

  # Utility methods follow
  
  def create_first_message
    msg = OutMessage.new
    msg.body = "Body of the message"
    msg.from = "Someone"
    msg.to = "Someone else"
    msg.guid = "someguid"
    msg.timestamp = Time.parse("Tue, 03 Jun 2003 09:39:21 GMT")
    msg.save
  end
  
  def create_second_message
    msg = OutMessage.new
    msg.body = "Body of the message 2"
    msg.from = "Someone 2"
    msg.to = "Someone else 2"
    msg.guid = "someguid 2"
    msg.timestamp = Time.parse("Thu, 03 Jun 2004 09:39:21 GMT")
    msg.save
  end
end
