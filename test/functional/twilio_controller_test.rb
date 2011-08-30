require 'test_helper'

class TwilioControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @application = Application.make :account => @account, :password => 'secret'
    @chan = Channel.make :twilio, :account => @account
  end
  
  test "receive message" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}
    
    post :index, message.merge(:account_id => @account.name)
    
    assert_response :ok
    assert_message message
  end
  
  test "receive confirmed ack" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    msg = AOMessage.make :account => @account, :channel => @chan, :state => 'delivered', :channel_relative_id => 'sms_sid'
    
    post :ack, :account_id => @account.name, :SmsStatus => 'sent', :AccountSid => @chan.configuration[:account_sid], :SmsSid => 'sms_sid'
    
    assert_response :ok
    assert_equal 'confirmed', msg.reload.state
  end
  
  test "receive failed ack" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    msg = AOMessage.make :account => @account, :channel => @chan, :state => 'delivered', :channel_relative_id => 'sms_sid'
    
    post :ack, :account_id => @account.name, :SmsStatus => 'failed', :AccountSid => @chan.configuration[:account_sid], :SmsSid => 'sms_sid'
    
    assert_response :ok
    assert_equal 'failed', msg.reload.state
  end
  
  test "fails authorization because of account" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}
    post :index, message.merge(:account_id => 'another')
    assert_response 401

    assert_equal 0, ATMessage.count
  end

  test "fails authorization because of incoming password" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming2')
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}
    post :index, message.merge(:account_id => @account.name)
    assert_response 401

    assert_equal 0, ATMessage.count
  end
  
  test "fails authorization because of account sid" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => 'another account sid'}
    post :index, message.merge(:account_id => @account.name)
    assert_response 401

    assert_equal 0, ATMessage.count
  end
  
  test "fails authorization because of channel name" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth('another channel name', @chan.configuration[:incoming_password])
    message = {:From => '123', :To => '456', :Body => 'Hello!', :SmsSid => 'sms_sid', :AccountSid => @chan.configuration[:account_sid]}
    post :index, message.merge(:account_id => @account.name)
    assert_response 401

    assert_equal 0, ATMessage.count
  end
  
  def assert_message message
    msgs = ATMessage.all
    assert_equal 1, msgs.length

    msg = msgs[0]
    assert_equal @account.id, msg.account_id
    assert_equal "sms://#{message[:From]}", msg.from
    assert_equal "sms://#{message[:To]}", msg.to
    assert_equal message[:Body], msg.body
    assert_equal message[:SmsSid], msg.channel_relative_id
    assert_equal 'queued', msg.state
    assert_not_nil msg.guid
  end

end
