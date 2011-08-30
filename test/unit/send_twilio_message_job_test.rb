require 'test_helper'

class SendTwilioMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :twilio, :name => "channel_name"
    @config = @chan.configuration
    stub_twilio
  end
  
  should "perform" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2'
    
    response = mock('response')
    @messages.expects(:create).returns(response)
    response.expects(:sid).returns('sms_sid')
    
    deliver msg
    
    msg = AOMessage.first
    assert_equal 'sms_sid', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
  
  should "perform error" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2'
    
    @messages.expects(:create).raises(Twilio::REST::ServerError.new)
    
    deliver msg
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'failed', msg.state
    
    @chan.reload
    assert @chan.enabled
  end
  
  should "perform authenticate error" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2'
    
    @messages.expects(:create).raises(Twilio::REST::RequestError.new("Authenticate"))
    
    begin
      deliver msg
    rescue => e
    else
      fail "Expected exception to be thrown"
    end
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'queued', msg.state
    
    @chan.reload
    assert @chan.enabled
  end
  
  should "perform with expected parameters" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2'
    
    response = mock('response')
    response.stubs(:sid).returns('sms_sid')
    
    @messages.expects(:create).with do |params|
      params[:from] == @config[:from] &&
      params[:to] == msg.to.without_protocol &&
      params[:body] == msg.subject_and_body
    end.returns(response)
    
    deliver msg
  end
  
  should "perform with callback url" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2'
    
    NamedRoutes.expects(:twilio_ack_url).returns('http://nuntium/foo/twilio/ack')
    
    response = mock('response')
    response.stubs(:sid).returns('sms_sid')
    
    @messages.expects(:create).with do |params|
      params[:status_callback] == "http://#{@chan.name}:#{@config[:incoming_password]}@nuntium/foo/twilio/ack"
    end.returns(response)
    
    deliver msg
  end
  
  def deliver(msg)
    job = SendTwilioMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end
  
  def stub_twilio
    twilio_client = mock('twilio')
    account = mock('account')
    sms = mock('sms')
    @messages = mock('messages')
    Twilio::REST::Client.expects(:new).with(@config[:account_sid], @config[:auth_token]).returns(twilio_client)
    twilio_client.stubs(:account).returns(account)
    account.stubs(:sms).returns(sms)
    sms.stubs(:messages).returns(@messages)
  end
  
end
