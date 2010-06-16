require 'test_helper'

class IncomingControllerTest < ActionController::TestCase

  def setup
    @account = Account.make :password
    @chan = Channel.make_unsaved :qst_server, :account => @account
    @chan.configuration[:password] = 'chan_pass'
    @chan.configuration[:password_confirmation] = 'chan_pass'
    @chan.configuration.delete :salt
    @chan.save!
    
    @application1 = Application.make :account => @account
    
    # This is so that we have another channel but the one we are looking for is used
    Channel.make :qst_serve, :account => @account
    
    # This is to see that this doesn't interfere with the test
    @account2 = Account.make
    @chan2 = Channel.make :qst_server, :account => @account2
    @application2 = Application.make :account => @account2
  end
  
  def get_last_id(expected)
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    head 'index', :account_id => @account.name
    assert_response :ok
    
    assert_equal expected, @response.headers['ETag']
  end

  test "get last message id" do
    new_at_message(@application1, 0)
    msg = new_at_message(@application1, 1)    
    new_at_message(@application2, 2)
    get_last_id msg.guid.to_s
  end
  
  test "get last message id not exists" do
    get_last_id ""
  end
  
  test "can't read" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    get 'index', :account_id => @account.name
    assert_response :not_found
  end
  
  def push(data)
    @request.env['RAW_POST_DATA'] = data
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    post 'create', :account_id => @account.name
    assert_response :ok
    
    messages = ATMessage.all
    assert_equal 1, messages.length
    
    messages[0]
  end
  
  test "push message" do
    msg = push <<-eos
      <?xml version="1.0" encoding="utf-8"?>
      <messages>
        <message id="someguid" from="Someone" to="Someone else" when="2008-09-24T17:12:57-03:00">
          <text>Hello!</text>
        </message>
      </messages>
    eos
    
    assert_equal msg.guid.to_s, @response.headers['ETag']
    
    assert_equal @account.id, msg.account_id
    assert_equal @application1.id, msg.application_id
    assert_equal "Hello!", msg.body
    assert_equal "Someone", msg.from
    assert_equal "Someone else", msg.to
    assert_equal "someguid", msg.guid
    assert_equal Time.parse("2008-09-24T17:12:57-03:00"), msg.timestamp
  end
  
  test "push message with custom attributes" do
    msg = push <<-eos
      <?xml version="1.0" encoding="utf-8"?>
      <messages>
        <message id="someguid" from="Someone" to="Someone else" when="2008-09-24T17:12:57-03:00">
          <text>Hello!</text>
          <property name="foo1" value="bar1" />
          <property name="foo1" value="bar2" />
          <property name="foo2" value="bar3" />
        </message>
      </messages>
    eos
    
    assert_equal ["bar1", "bar2"], msg.custom_attributes['foo1']
    assert_equal "bar3", msg.custom_attributes['foo2']
  end
  
  test "get last message id not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'wrong_chan_pass')
    head 'index', :account_id => @account.name
    assert_response 401
  end
  
  test "push messages not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'wrong_chan_pass')
    post 'create', :account_id => @account.name
    assert_response 401
  end
    
end
