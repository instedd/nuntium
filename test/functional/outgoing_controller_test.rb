require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  test "get one" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
    new_ao_message(app, 0)
    new_qst_outgoing_message(chan, 0)
  
    get :index
    
    assert_equal "someguid 0", @response.headers['ETag']
    
    assert_select "message[id=?]", "someguid 0"
    assert_select "message[from=?]", "Someone 0"
    assert_select "message[to=?]", "Someone else 0"
    assert_select "message[when=?]", "2003-06-03T09:39:21Z"
    assert_select "message text", "Body of the message 0"
    
    unread = QSTOutgoingMessage.all    
    assert_equal 1, unread.length
    assert_equal chan.id, unread[0].channel_id
    assert_equal "someguid 0", unread[0].guid
    
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get :index
    
    assert_select "message", {:count => 0}
  end
  
  test "get one not unread" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
    new_ao_message(app, 0)
  
    get :index
    assert_select "message", {:count => 0}
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
    new_ao_message(app, 0)
    new_qst_outgoing_message(chan, 0)
    
    new_ao_message(app, 1)
    new_qst_outgoing_message(chan, 1)
  
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 1"
    get :index
    
    assert_select "message", {:count => 0}
    
    assert_equal 0, QSTOutgoingMessage.all.length
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
  
    new_ao_message(app, 0)
    new_qst_outgoing_message(chan, 0)
    
    new_ao_message(app, 1)
    new_qst_outgoing_message(chan, 1)
  
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
    app, chan = create_app_and_channel('user', 'pass', 'chan', 'chan_pass')
    
    (1..4).each do |i| 
      new_ao_message(app, i)
      new_qst_outgoing_message(chan, i)
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
  
end
