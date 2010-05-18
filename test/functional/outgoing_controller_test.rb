require 'test_helper'

class OutgoingControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @chan = Channel.make_unsaved :qst_server, :account => @account
    @chan.configuration[:password] = 'chan_pass'
    @chan.configuration[:password_confirmation] = 'chan_pass'
    @chan.configuration.delete :salt
    @chan.save!
    
    @account2 = Account.make
    @chan2 = Channel.make :qst_server, :account => @account2
    
    Channel.make_unsaved :qst_server, :account => @account
  end

  test "get one" do
    msg2 = new_ao_message(@account2, 1)
    new_qst_outgoing_message(@chan2, msg2.id)
    
    msg = new_ao_message(@account, 0)
    new_qst_outgoing_message(@chan, msg.id)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    get 'index', :account_id => @account.name
    
    assert_equal msg.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg
    
    unread = QSTOutgoingMessage.all
    assert_equal 2, unread.length
    
    assert_equal @chan2.id, unread[0].channel_id
    assert_equal msg2.id, unread[0].ao_message_id
    
    assert_equal @chan.id, unread[1].channel_id
    assert_equal msg.id, unread[1].ao_message_id
    
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid
    get 'index', :account_id => @account.name
    
    assert_select "message", {:count => 0}
  end
  
  test "get one with custom properties" do
    msg = new_ao_message(@account, 0)
    msg.custom_attributes['foo1'] = 'bar1'
    msg.custom_attributes['foo2'] = 'bar2'
    msg.save!
    
    new_qst_outgoing_message(@chan, msg.id)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    get 'index', :account_id => @account.name
    
    assert_select "message", {:count => 1}
    assert_shows_message msg
  end
  
  test "get one not unread" do
    new_ao_message(@account, 0)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    get 'index', :account_id => @account.name
    assert_select "message", {:count => 0}
  end
  
  test "get one increments retires" do
    msg = new_ao_message(@account, 0)
    new_qst_outgoing_message(@chan, msg.id)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    
    1.upto 3 do |i|
      get 'index', :account_id => @account.name
      assert_select "message", {:count => 1}
      assert_equal i, AOMessage.first.tries
    end
    
    # Try number 4 -> should be gone
    get 'index', :account_id => @account.name
    assert_select "message", {:count => 0}
    assert_equal 'failed', AOMessage.first.state
  end
  
  test "should return not modified for HTTP_IF_NONE_MATCH" do
    msg2 = new_ao_message(@account2, 2)
    new_qst_outgoing_message(@chan2, msg2.id)
    
    msg0 = new_ao_message(@account, 0)
    new_qst_outgoing_message(@chan, msg0.id)
    
    msg1 = new_ao_message(@account, 1)
    new_qst_outgoing_message(@chan, msg1.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msg1.guid
    get 'index', :account_id => @account.name
    
    assert_select "message", {:count => 0}
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal @chan2.id, unread[0].channel_id
    assert_equal msg2.id, unread[0].ao_message_id
  end
  
  test "should apply HTTP_IF_NONE_MATCH" do
    msg0 = new_ao_message(@account, 0)
    new_qst_outgoing_message(@chan, msg0.id)
    
    msg1 = new_ao_message(@account, 1)
    new_qst_outgoing_message(@chan, msg1.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msg0.guid
    get 'index', :account_id => @account.name
    
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
    msgs = []
    
    (1..4).each do |i|
      msg = new_ao_message(@account, i) 
      msgs.push msg
      new_qst_outgoing_message(@chan, msg.id)
    end
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msgs[1].guid.to_s
    get 'index', :account_id => @account.name, :max => 1
    
    assert_equal msgs[2].id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msgs[2]
    
    unread = QSTOutgoingMessage.all
    assert_equal 2, unread.length
    assert_equal msgs[2].id, unread[0].ao_message_id
    assert_equal msgs[3].id, unread[1].ao_message_id
  end
  
  test "get not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'wrong_pass')  
    get 'index', :account_id => @account.name
    
    assert_response 401
  end
  
  test "should apply HTTP_IF_NONE_MATCH real example" do
    # First
    msg = new_ao_message(@account, 0)
    new_qst_outgoing_message(@chan, msg.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    get 'index', :account_id => @account.name
    
    assert_equal msg.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg
    
    # Second
    msg1 = new_ao_message(@account, 1)
    new_qst_outgoing_message(@chan, msg1.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid.to_s
    get 'index', :account_id => @account.name
    
    assert_equal msg1.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg1
  end
  
  test "should skip failed messages" do
    10.times do |i|
      msg = new_ao_message(@account, i)
      msg.tries = 4
      msg.save!
      new_qst_outgoing_message(@chan, msg.id)
    end
    
    msg11 = new_ao_message(@account, 11)
    new_qst_outgoing_message(@chan, msg11.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')    
    get 'index', :account_id => @account.name
    
    assert_equal msg11.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg11
    
    # One unread message
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal msg11.id, unread[0].ao_message_id
  end
  
  test "should work if HTTP_IF_NONE_MATCH is not found" do
    msg = new_ao_message(@account, 0)
    new_qst_outgoing_message(@chan, msg.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 3"
    get 'index', :account_id => @account.name
    
    assert_equal msg.id.to_s, @response.headers['ETag']
    
    assert_select "message", {:count => 1}
    assert_shows_message msg
    
    unread = QSTOutgoingMessage.all
    assert_equal 1, unread.length
  end
  
  test "bug update wrong ao messages" do
    msg2 = new_ao_message(@account2, 0)
    msg2.save!
    new_qst_outgoing_message(@chan2, msg2.id)
    
    original_state = msg2.state
  
    msg = new_ao_message(@account, 1)
    msg.save!
    new_qst_outgoing_message(@chan, msg.id)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid    
    get 'index', :account_id => @account.name
    
    assert_equal original_state, AOMessage.find(msg2.id).state
  end
  
end
