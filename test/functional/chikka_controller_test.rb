require 'test_helper'

class ChikkaControllerTest < ActionController::TestCase
  setup do
    @channel = ChikkaChannel.make
    @account = @channel.account
    @request_id = "5048303030534D415254303030303032393230303032303030303030303133323030303036333933393932333934303030303030313331313035303735383137"
    @incoming_message = {
      account_name: @account.name,
      channel_name: @channel.name,
      secret_token: @channel.secret_token,
      message_type: "incoming",
      mobile_number: "639181234567",
      shortcode: @channel.shortcode,
      request_id: @request_id,
      message: "This is a test message",
      timestamp: "1383609498.44"
    }
    @delivery_notification = {
      account_name: @account.name,
      channel_name: @channel.name,
      secret_token: @channel.secret_token,
      message_type: "outgoing",
      shortcode: @channel.shortcode,
      status: "SENT",
      credits_cost: "0.50",
      timestamp: "1383609498.44"
    }
  end

  test "receive incoming message" do
    post :incoming, @incoming_message

    assert_response :ok
    assert_equal 'Accepted', @response.body

    msg = AtMessage.last
    assert_equal @account.id, msg.account_id
    assert_equal @channel.id, msg.channel_id
    assert_equal "sms://639181234567", msg.from
    assert_equal "sms://#{@channel.shortcode}", msg.to
    assert_equal @request_id, msg.channel_relative_id
    assert_equal "This is a test message", msg.body
  end

  test "reject message if the secret token doesn't match" do
    post :incoming, @incoming_message.merge(secret_token: "INVALID")
    assert_response :unauthorized
    assert_equal 'Error', @response.body
  end

  test "reject message if the shortcode doesn't match" do
    post :incoming, @incoming_message.merge(shortcode: "1234")
    assert_response :unauthorized
    assert_equal 'Error', @response.body
  end

  test "receive delivery notification" do
    msg = AoMessage.make account: @account, channel: @channel, state: 'delivered'
    msg.channel_relative_id = msg.guid.delete('-')
    msg.save!

    post :ack, @delivery_notification.merge(message_id: msg.channel_relative_id)

    assert_response :ok
    assert_equal 'Accepted', @response.body

    msg.reload
    assert_equal 'confirmed', msg.state
    assert_equal "0.50", msg.custom_attributes["chikka_credits_cost"]
    assert_equal "SENT", msg.custom_attributes["chikka_status"]
  end

  test "reject delivery notification if the secret token doesn't match" do
    post :ack, @delivery_notification.merge(secret_token: "INVALID")
    assert_response :unauthorized
    assert_equal 'Error', @response.body
  end

  test "reject delivery notification if the message could not be found" do
    post :ack, @delivery_notification.merge(message_id: "0000")
    assert_response :not_found
    assert_equal 'Error', @response.body
  end
end
