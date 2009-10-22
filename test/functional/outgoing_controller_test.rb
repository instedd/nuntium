require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  test "get one" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    
    # This is to see that this doesn't interfere with the test
    app2, chan2 = create_app_and_channel('app2', 'app_pass2', 'chan2', 'chan_pass2')
    
    # This is so that we have another channel but the one we are looking for is used
    create_channel(app, 'chan3', 'chan_pass3')
    
    new_ao_message(app2, 1)
    new_qst_outgoing_message(chan2, 1)
    
    new_ao_message(app, 0)
    new_qst_outgoing_message(chan, 0)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    get 'index', :application_id => 'app'
    
    assert_equal "someguid 0", @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    
    assert_select "message[id=?]", "someguid 0"
    assert_select "message[from=?]", "Someone 0"
    assert_select "message[to=?]", "Someone else 0"
    assert_select "message[when=?]", "2003-06-03T09:39:21Z"
    assert_select "message text", "Body of the message 0"
    
    unread = QSTOutgoingMessage.all
    assert_equal 2, unread.length
    
    assert_equal chan2.id, unread[0].channel_id
    assert_equal "someguid 1", unread[0].guid
    
    assert_equal chan.id, unread[1].channel_id
    assert_equal "someguid 0", unread[1].guid
    
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get 'index', :application_id => 'app'
    
    assert_select "message", {:count => 0}
  end
  
  test "get one not unread" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    new_ao_message(app, 0)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    get 'index', :application_id => 'app'
    assert_select "message", {:count => 0}
  end
  
  test "get one increments retires" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    
    new_ao_message(app, 0)
    new_qst_outgoing_message(chan, 0)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    
    # Try number 1
    get 'index', :application_id => 'app'
    assert_select "message", {:count => 1}
    assert_equal 1, AOMessage.first.tries
    
    # Try number 2
    get 'index', :application_id => 'app'
    assert_select "message", {:count => 1}
    assert_equal 2, AOMessage.first.tries
    
    # Try number 3
    get 'index', :application_id => 'app'
    assert_select "message", {:count => 1}
    assert_equal 3, AOMessage.first.tries
    
    # Try number 4 -> should be gone
    get 'index', :application_id => 'app'
    assert_select "message", {:count => 0}
    assert_equal 0, AOMessage.all.length
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    app2, chan2 = create_app_and_channel('app2', 'app_pass2', 'chan2', 'chan_pass2')
    
    new_ao_message(app2, 2)
    new_qst_outgoing_message(chan2, 2)
    
    new_ao_message(app, 0)
    new_qst_outgoing_message(chan, 0)
    
    new_ao_message(app, 1)
    new_qst_outgoing_message(chan, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 1"
    get 'index', :application_id => 'app'
    
    assert_select "message", {:count => 0}
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal chan2.id, unread[0].channel_id
    assert_equal "someguid 2", unread[0].guid
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
  
    new_ao_message(app, 0)
    new_qst_outgoing_message(chan, 0)
    
    new_ao_message(app, 1)
    new_qst_outgoing_message(chan, 1)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 0"
    get 'index', :application_id => 'app'
    
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
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    
    (1..4).each do |i| 
      new_ao_message(app, i)
      new_qst_outgoing_message(chan, i)
    end
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 2"
    get 'index', :application_id => 'app', :max => 1
    
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
  
  test "get not authorized" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass')
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'wrong_pass')  
    get 'index', :application_id => 'app'
    
    assert_response 401
  end
  
end
