require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  test "get one" do
    create_ao_message(0)
    create_qst_outgoing_message(0)
  
    get :index
    
    assert_equal "someguid 0", @response.headers['ETag']
    
    assert_select "message[id=?]", "someguid 0"
    assert_select "message[from=?]", "Someone 0"
    assert_select "message[to=?]", "Someone else 0"
    assert_select "message[when=?]", "2003-06-03T09:39:21Z"
    assert_select "message text", "Body of the message 0"
    
    unread = QSTOutgoingMessage.all    
    assert_equal 1, unread.length
    assert_equal "someguid 0", unread[0].guid
    
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get :index
    
    assert_select "message", {:count => 0}
  end
  
  test "get one not unread" do
    create_ao_message(0)
  
    get :index
    assert_select "message", {:count => 0}
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    create_ao_message(0)
    create_qst_outgoing_message(0)
    
    create_ao_message(1)
    create_qst_outgoing_message(1)
  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 1"
    get :index
    
    assert_select "message", {:count => 0}
    
    assert_equal 0, QSTOutgoingMessage.all.length
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    create_ao_message(0)
    create_qst_outgoing_message(0)
    
    create_ao_message(1)
    create_qst_outgoing_message(1)
  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get :index
    
    assert_equal "someguid 1", @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    
    assert_select "message[id=?]", "someguid 1"
    assert_select "message[from=?]", "Someone 1"
    assert_select "message[to=?]", "Someone else 1"
    assert_select "message[when=?]", "2004-06-03T09:39:21Z"
    assert_select "message text", "Body of the message 1"
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal "someguid 1", unread[0].guid
  end
  
  test "should apply HTTP_IF_NONE_MATCH with max" do
    (1..4).each do |i| 
      create_ao_message(i)
      create_qst_outgoing_message(i)
    end
  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 2"
    get :index, :max => 1
    
    assert_equal "someguid 3", @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    
    assert_select "message[id=?]", "someguid 3"
    assert_select "message[from=?]", "Someone 3"
    assert_select "message[to=?]", "Someone else 3"
    assert_select "message[when=?]", "2006-06-03T09:39:21Z"
    assert_select "message text", "Body of the message 3"
    
    unread = QSTOutgoingMessage.all
    assert_equal 2, unread.length
    assert_equal "someguid 3", unread[0].guid
    assert_equal "someguid 4", unread[1].guid
  end

  # Utility methods follow
  
  def create_ao_message(i)
    msg = AOMessage.new
    msg.body = "Body of the message #{i}"
    msg.from = "Someone #{i}"
    msg.to = "Someone else #{i}"
    msg.guid = "someguid #{i}"
    msg.timestamp = Time.parse("03 Jun #{2003+i} 09:39:21 GMT")
    msg.save
  end
  
  def create_qst_outgoing_message(i)
    msg = QSTOutgoingMessage.new
    msg.guid = "someguid #{i}"
    msg.save
  end
  
end
