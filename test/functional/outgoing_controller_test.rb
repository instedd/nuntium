require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  test "get one" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
    
    # This is to see that this doesn't interfere with the test
    app2, chan2 = create_app_and_channel('app2', 'app_pass2', 'chan2', 'chan_pass2', 'qst_server')
    
    # This is so that we have another channel but the one we are looking for is used
    create_channel(app, 'chan3', 'chan_pass3', 'qst_server')
    
    msg2 = new_ao_message(app2, 1)
    new_qst_outgoing_message(chan2, msg2.id)
    
    msg = new_ao_message(app, 0)
    new_qst_outgoing_message(chan, msg.id)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    get 'index', :application_id => 'app'
    
    assert_equal msg.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg
    
    unread = QSTOutgoingMessage.all
    assert_equal 2, unread.length
    
    assert_equal chan2.id, unread[0].channel_id
    assert_equal msg2.id, unread[0].ao_message_id
    
    assert_equal chan.id, unread[1].channel_id
    assert_equal msg.id, unread[1].ao_message_id
    
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid
    get 'index', :application_id => 'app'
    
    assert_select "message", {:count => 0}
  end
  
  test "get one not unread" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
    new_ao_message(app, 0)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    get 'index', :application_id => 'app'
    assert_select "message", {:count => 0}
  end
  
  test "get one increments retires" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
    
    msg = new_ao_message(app, 0)
    new_qst_outgoing_message(chan, msg.id)
    
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
    assert_equal 'failed', AOMessage.first.state
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
    app2, chan2 = create_app_and_channel('app2', 'app_pass2', 'chan2', 'chan_pass2', 'qst_server')
    
    msg2 = new_ao_message(app2, 2)
    new_qst_outgoing_message(chan2, msg2.id)
    
    msg0 = new_ao_message(app, 0)
    new_qst_outgoing_message(chan, msg0.id)
    
    msg1 = new_ao_message(app, 1)
    new_qst_outgoing_message(chan, msg1.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msg1.guid
    get 'index', :application_id => 'app'
    
    assert_select "message", {:count => 0}
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal chan2.id, unread[0].channel_id
    assert_equal msg2.id, unread[0].ao_message_id
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
  
    msg0 = new_ao_message(app, 0)
    new_qst_outgoing_message(chan, msg0.id)
    
    msg1 = new_ao_message(app, 1)
    new_qst_outgoing_message(chan, msg1.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msg0.guid
    get 'index', :application_id => 'app'
    
    assert_equal msg1.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg1
    
    # One unread message was deleted
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal msg1.id, unread[0].ao_message_id
    
    # The first message is marked as delivered,
    # the second stays as queued
    msgs = AOMessage.all
    
    assert_equal 'delivered', msgs[0].state
    assert_equal 'queued', msgs[1].state
  end
  
  test "should apply HTTP_IF_NONE_MATCH with max" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
    
    msgs = []
    
    (1..4).each do |i|
      msg = new_ao_message(app, i) 
      msgs.push msg
      new_qst_outgoing_message(chan, msg.id)
    end
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msgs[1].guid.to_s
    get 'index', :application_id => 'app', :max => 1
    
    assert_equal msgs[2].id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msgs[2]
    
    unread = QSTOutgoingMessage.all
    assert_equal 2, unread.length
    assert_equal msgs[2].id, unread[0].ao_message_id
    assert_equal msgs[3].id, unread[1].ao_message_id
  end
  
  test "get not authorized" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'wrong_pass')  
    get 'index', :application_id => 'app'
    
    assert_response 401
  end
  
  test "should apply HTTP_IF_NONE_MATCH real example" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
  
    # First
    msg = new_ao_message(app, 0)
    new_qst_outgoing_message(chan, msg.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')
    get 'index', :application_id => 'app'
    
    assert_equal msg.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg
    
    # Second
    msg1 = new_ao_message(app, 1)
    new_qst_outgoing_message(chan, msg1.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid.to_s
    get 'index', :application_id => 'app'
    
    assert_equal msg1.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg1
  end
  
  test "should work if HTTP_IF_NONE_MATCH is not found" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server')
  
    msg = new_ao_message(app, 0)
    new_qst_outgoing_message(chan, msg.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 3"
    get 'index', :application_id => 'app'
    
    assert_equal msg.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
  end
  
end
