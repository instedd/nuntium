require 'test_helper'

class ChannelsUiControllerTest < ActionController::TestCase
  def setup
    @user = User.make
    @account = @user.create_account Account.make_unsaved
    sign_in @user
    TwilioChannel.any_instance.stubs(:configure_phone_number).returns(true)
  end

  test "creates Twilio channel" do
    params = {
      "kind"=>"twilio",
      "config"=>
        {
          "name"=>"foo",
          "account_sid"=>"bar",
          "auth_token"=>"foobar123",
          "from"=>"12345678"
        }
    }
    post :create, params

    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, TwilioChannel.default_protocol

    assert_equal chan.name, params['config']['name']
    assert_equal chan.account_sid, params['config']['account_sid']
    assert_equal chan.auth_token, params['config']['auth_token']
    assert_equal chan.from, params['config']['from']
  end

  test "updates Twilio channel" do
    channel = TwilioChannel.make account: @account, name: "foo"
    config = channel.configuration
    config[:name] = "bar"

    post :update, :config => config, :id => channel.id
    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, TwilioChannel.default_protocol

    assert_equal chan.name, "bar"
    assert_equal chan.account_sid, config[:account_sid]
    assert_equal chan.auth_token, config[:auth_token]
    assert_equal chan.from, config[:from]
  end
end
