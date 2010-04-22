require 'test_helper'

class IncomingControllerTest < ActionController::TestCase
  test "get last message id" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    new_at_message(account, 0)
    msg = new_at_message(account, 1)
    
    # This is so that we have another channel but the one we are looking for is used
    create_channel(account, 'chan3', 'chan_pass3', 'qst_server')
    
    # This is to see that this doesn't interfere with the test
    account2, chan2 = create_account_and_channel('account2', 'account_pass2', 'chan2', 'chan_pass2', 'qst_server')
    new_at_message(account2, 2)
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')
    head 'index', :account_id => 'account'
    
    assert_response :ok
    assert_equal msg.guid.to_s, @response.headers['ETag']
  end
  
  test "get last message id not exists" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')
    head 'index', :account_id => 'account'
    
    assert_response :ok
    assert_equal "", @response.headers['ETag']
  end
  
  test "can't read" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')
    get 'index', :account_id => 'account'
    
    assert_response :not_found
  end
  
  test "push message" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
  
    @request.env['RAW_POST_DATA'] = <<-eos
      <?xml version="1.0" encoding="utf-8"?>
      <messages>
        <message id="someguid" from="Someone" to="Someone else" when="2008-09-24T17:12:57-03:00">
          <text>Hello!</text>
        </message>
      </messages>
    eos
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')
    post 'create', :account_id => 'account'
    
    messages = ATMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_response :ok
    assert_equal msg.guid.to_s, @response.headers['ETag']
    
    assert_equal account.id, msg.account_id
    assert_equal "Hello!", msg.body
    assert_equal "Someone", msg.from
    assert_equal "Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal Time.parse("2008-09-24T17:12:57-03:00"), msg.timestamp
  end
  
  test "push message with custom attributes" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')
  
    @request.env['RAW_POST_DATA'] = <<-eos
      <?xml version="1.0" encoding="utf-8"?>
      <messages>
        <message id="someguid" from="Someone" to="Someone else" when="2008-09-24T17:12:57-03:00">
          <text>Hello!</text>
          <property name="foo1" value="bar1" />
          <property name="foo2" value="bar2" />
        </message>
      </messages>
    eos
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'chan_pass')
    post 'create', :account_id => 'account'
    
    messages = ATMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_response :ok
    assert_equal "bar1", msg.custom_attributes['foo1']
    assert_equal "bar2", msg.custom_attributes['foo2']
  end
  
  test "get last message id not authorized" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')

    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'wrong_chan_pass')
    head 'index', :account_id => 'account'
    
    assert_response 401
  end
  
  test "push messages not authorized" do
    account, chan = create_account_and_channel('account', 'account_pass', 'chan', 'chan_pass', 'qst_server')

    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'wrong_chan_pass')
    post 'create', :account_id => 'account'
    
    assert_response 401
  end
    
end
