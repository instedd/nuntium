require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  test "get one" do
    create_message(0)
  
    get :index
    
    assert_select "message[id=?]", "someguid 0"
    assert_select "message[from=?]", "Someone 0"
    assert_select "message[to=?]", "Someone else 0"
    assert_select "message[when=?]", "Tue, 03 Jun 2003 09:39:21 +0000"
    assert_select "message text", "Body of the message 0"
  end
  
  test "should return not modified for If-Modified-Since" do
    create_message(0)
    create_message(1)
  
    @request.env["If-Modified-Since"] = "Thu, 03 Jun 2004 09:39:21 GMT"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply If-Modified-Since" do
    create_message(0)
    create_message(1)
  
    @request.env["If-Modified-Since"] = "Tue, 03 Jun 2003 09:39:21 GMT"
    get :index
    
    assert_select "message" do |es|
      assert_equal 1, es.length
    end
    
    assert_select "message[id=?]", "someguid 1"
    assert_select "message[from=?]", "Someone 1"
    assert_select "message[to=?]", "Someone else 1"
    assert_select "message[when=?]", "Thu, 03 Jun 2004 09:39:21 +0000"
    assert_select "message text", "Body of the message 1"
  end
  
  test "should return not modified for If-None-Match" do
    create_message(0)
    create_message(1)
  
    @request.env["If-None-Match"] = "someguid 1"
    get :index
    
    assert_response :not_modified
  end
  
  test "should apply If-None-Match" do
    create_message(0)
    create_message(1)
  
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
  end
  
  test "should apply If-None-Match with max" do
    (1..10).each { |i| create_message(i) }
  
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
  
end
