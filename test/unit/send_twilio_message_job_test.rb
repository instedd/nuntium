require 'test_helper'

class SendTwilioMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :twilio
    @config = @chan.configuration
    stub_twilio
  end
  
  should "perform" do
    msg = AOMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'
    
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
    msg = AOMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'
    
    @messages.expects(:create).raises(Twilio::REST::ServerError.new)
    
    deliver msg
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'failed', msg.state
    
    @chan.reload
    assert @chan.enabled
  end
  
  should "perform authenticate error" do
    msg = AOMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'
    
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
