require 'test_helper'

class ChannelsUiControllerTest < ActionController::TestCase
  def setup
    @user = User.make
    @account = @user.create_account Account.make_unsaved
    sign_in @user
    TwilioChannel.any_instance.stubs(:configure_phone_number).returns(true)

    @twilio_params = { "kind" => "twilio", "config" => { "name" => "foo", "account_sid" => "545454", "auth_token" => "656565", "from" => "12345678" } }
    @chikka_params = { "kind" => "chikka", "config" => { "name" => "foo", "shortcode" => "545454", "client_id" => "27", "secret_key" => "656565", "secret_token" => "36d0ef4b"} }
    @africas_talking_params = { "kind" => "africas_talking", "config" => { "name" => "foo", "username" => "john doe", "api_key" => "55ee11ff", "shortcode" => "545454", "secret_token" => "36d0ef4b", "use_sandbox" => "1" } }
  end

  test "creates Twilio channel" do
    post :create, @twilio_params

    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, TwilioChannel.default_protocol

    assert_equal chan.name, @twilio_params['config']['name']
    assert_equal chan.account_sid, @twilio_params['config']['account_sid']
    assert_equal chan.auth_token, @twilio_params['config']['auth_token']
    assert_equal chan.from, @twilio_params['config']['from']
  end

  test "creates Chikka channel" do
    post :create, @chikka_params

    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, ChikkaChannel.default_protocol

    assert_equal chan.name, @chikka_params['config']['name']
    assert_equal chan.shortcode, @chikka_params['config']['shortcode']
    assert_equal chan.client_id, @chikka_params['config']['client_id']
    assert_equal chan.secret_token, @chikka_params['config']['secret_token']
  end

  test "creates Africas Talking channel" do
    post :create, @africas_talking_params

    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, AfricasTalkingChannel.default_protocol

    assert_equal chan.name, @africas_talking_params['config']['name']
    assert_equal chan.username, @africas_talking_params['config']['username']
    assert_equal chan.api_key, @africas_talking_params['config']['api_key']
    assert_equal chan.shortcode, @africas_talking_params['config']['shortcode']
    assert_equal chan.secret_token, @africas_talking_params['config']['secret_token']
    assert_equal chan.use_sandbox, @africas_talking_params['config']['use_sandbox']
  end

  test "updates Twilio channel" do
    post :create, @twilio_params
    chan = Channel.all[0]
    twilio_config_v2 = { "name" => "foo_v2", "account_sid" => "545454_v2", "auth_token" => "656565_v2", "from" => "123456782" }

    post :update, :config => twilio_config_v2, :id => chan.id
    chan = Channel.all[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, TwilioChannel.default_protocol

    assert_equal chan.name, twilio_config_v2["name"]
    assert_equal chan.account_sid, twilio_config_v2["account_sid"]
    assert_equal chan.auth_token, twilio_config_v2["auth_token"]
    assert_equal chan.from, twilio_config_v2["from"]
  end

  test "updates Chikka channel" do
    post :create, @chikka_params
    chan = Channel.all[0]
    chikka_config_v2 = { "name" => "foo_v2", "shortcode" => "545454_v2", "client_id" => "272", "secret_key" => "656565_v2", "secret_token" => "36d0efv2" }

    post :update, :config => chikka_config_v2, :id => chan.id
    chan = Channel.all[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, ChikkaChannel.default_protocol

    assert_equal chan.name, chikka_config_v2["name"]
    assert_equal chan.shortcode, chikka_config_v2["shortcode"]
    assert_equal chan.client_id, chikka_config_v2["client_id"]
    assert_equal chan.secret_key, chikka_config_v2["secret_key"]
    assert_equal chan.secret_token, chikka_config_v2["secret_token"]
  end

  test "updates AfricasTalking channel" do
    post :create, @africas_talking_params
    chan = Channel.all[0]
    africas_talking_config_v2 = { "name" => "foo_v2", "username" => "johny doe", "api_key" => "55ee11ff_v2", "shortcode" => "545454_v2", "secret_token" => "36d0efv2", "use_sandbox" => "0" }

    post :update, :config => africas_talking_config_v2, :id => chan.id
    chan = Channel.all[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, AfricasTalkingChannel.default_protocol

    assert_equal chan.name, africas_talking_config_v2['name']
    assert_equal chan.username, africas_talking_config_v2['username']
    assert_equal chan.api_key, africas_talking_config_v2['api_key']
    assert_equal chan.shortcode, africas_talking_config_v2['shortcode']
    assert_equal chan.secret_token, africas_talking_config_v2['secret_token']
    assert_equal chan.use_sandbox, africas_talking_config_v2['use_sandbox']
  end
end
