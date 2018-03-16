require 'test_helper'

class SendChikkaMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = ChikkaChannel.make
  end

  test "send message" do
    msg = AoMessage.make account: Account.make, channel: @chan, guid: '49292c60-0d22-47d2-9721-71e602ae94bb'

    stub = expect_smsapi_request(msg).to_return(accepted_response)
    deliver msg
    assert_requested stub

    msg = AoMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
    assert_equal '49292c600d2247d2972171e602ae94bb', msg.channel_relative_id
  end

  test "mark message as failed when received status with 'Invalid Mobile Number'" do
    msg = AoMessage.make account: Account.make, channel: @chan

    stub = expect_smsapi_request(msg).to_return(invalid_mobile_number_response)
    deliver msg
    assert_requested stub

    msg = AoMessage.first
    assert_equal 'failed', msg.state
  end

  test "send message as a reply when there is a recent AT message for the same number" do
    from = 'sms://123456789'
    at1 = AtMessage.make account: @chan.account, channel: @chan, from: from, channel_relative_id: '12345'
    at2 = AtMessage.make account: @chan.account, channel: @chan, from: from, channel_relative_id: '67890'
    ao = AoMessage.make account: @chan.account, channel: @chan, to: from

    stub = expect_smsapi_request(ao, {message_type: 'REPLY', request_id: '67890', request_cost: 'FREE'})
      .to_return(accepted_response)
    deliver ao
    assert_requested stub
  end

  test "do not send a reply when the latest AT message was received an hour ago" do
    from = 'sms://123456789'
    at = AtMessage.make account: @chan.account, channel: @chan, from: from, channel_relative_id: '12345', created_at: Time.now - 1.hour
    ao = AoMessage.make account: @chan.account, channel: @chan, to: from

    stub = expect_smsapi_request(ao).to_return(accepted_response)
    deliver ao
    assert_requested stub
  end

  def expect_smsapi_request(msg, params = {})
    query_parameters = {
      message_type: 'SEND',
      mobile_number: msg.to.without_protocol,
      shortcode: @chan.configuration[:shortcode],
      message_id: msg.guid.delete('-'),
      message: msg.body,
      client_id: @chan.configuration[:client_id],
      secret_key: @chan.configuration[:secret_key]
    }

    body = query_parameters.merge(params)
    stub_request(:post, 'https://post.chikka.com/smsapi/request').with(body: body)
  end

  def deliver(msg)
    job = SendChikkaMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end

  def accepted_response
    {
      status: 200,
      message: 'ACCEPTED',
      body: '{"status":200,"message":"ACCEPTED"}'
    }
  end

  def invalid_mobile_number_response
    {
      status: 400,
      message: 'BAD REQUEST',
      body: '{"status":400,"message":"BAD REQUEST","description":"Invalid Mobile Number"}'
    }
  end
end
