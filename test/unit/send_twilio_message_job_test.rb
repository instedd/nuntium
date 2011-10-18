require 'test_helper'

class SendTwilioMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = TwilioChannel.make
    @config = @chan.configuration
    stub_twilio
    @msg = AoMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2', :subject => "a subject", :body => "a body"
  end

  should "perform" do
    response = mock('response')
    @messages.expects(:create).returns(response)
    response.expects(:sid).returns('sms_sid')

    deliver @msg

    msg = AoMessage.first
    assert_equal 'sms_sid', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

  should "perform error" do
    @messages.expects(:create).raises(Twilio::REST::ServerError.new)

    deliver @msg

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'failed', msg.state

    @chan.reload
    assert @chan.enabled
  end

  should "perform authenticate error" do
    @messages.expects(:create).raises(Twilio::REST::RequestError.new("Authenticate"))

    begin
      deliver @msg
    rescue => e
    else
      fail "Expected exception to be thrown"
    end

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'queued', msg.state

    @chan.reload
    assert @chan.enabled
  end

  should "perform with expected parameters" do
    response = mock('response')
    response.stubs(:sid).returns('sms_sid')

    @messages.expects(:create).with do |params|
      params[:from] == @config[:from] &&
      params[:to] == @msg.to.without_protocol &&
      params[:body] == @msg.subject_and_body
    end.returns(response)

    deliver @msg
  end

  should "perform with callback url" do
    NamedRoutes.expects(:twilio_ack_url).returns('http://nuntium/foo/twilio/ack')

    response = mock('response')
    response.stubs(:sid).returns('sms_sid')

    @messages.expects(:create).with do |params|
      params[:status_callback] == "http://#{@chan.name}:#{@config[:incoming_password]}@nuntium/foo/twilio/ack"
    end.returns(response)

    deliver @msg
  end

  should "perform with long messages" do
    long_msg = AoMessage.make :account => @chan.account, :channel => @chan, :guid => '1-2', :subject => nil, :body => ("a" * 160 + "b" * 40)

    # First part of the message
    response = mock('response')
    @messages.expects(:create).with do |params|
      params[:from] == @config[:from] &&
      params[:to] == long_msg.to.without_protocol &&
      params[:body] == "a" * 160
    end.returns(response)
    response.expects(:sid).returns('sms_sid')

    # Second part
    @messages.expects(:create).with do |params|
      params[:from] == @config[:from] &&
      params[:to] == long_msg.to.without_protocol &&
      params[:body] == "b" * 40
    end

    deliver long_msg

    long_msg.reload
    assert_equal 'sms_sid', long_msg.channel_relative_id
    assert_equal 1, long_msg.tries
    assert_equal 'delivered', long_msg.state
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
