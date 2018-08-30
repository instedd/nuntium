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
    @smpp_params = { "kind" => "smpp", "config" => { "name" => "foo", "host" => "nexmo", "port" => "8080", "user" => "john doe", "password" => "1234", "system_type" =>  "vma", "source_ton" => "1", "source_npi" => "2", "destination_ton" => "1", "destination_npi" => "2", "endianness_mo" => "little", "endianness_mt" => "big", "accept_mo_hex_string" => "1", "default_mo_encoding" => "ucs-2", "mt_encodings" => ["ascii"], "mt_max_length" => "140", "mt_csms_method" => "udh", "suspension_codes" => [], "rejection_codes" => [] } }
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

  test "creates SMPP channel" do
    post :create, @smpp_params

    chans = Channel.all
    assert_equal 1, chans.length
    chan = chans[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, SmppChannel.default_protocol

    assert_equal chan.name, @smpp_params['config']['name']
    assert_equal chan.host, @smpp_params['config']['host']
    assert_equal chan.port, @smpp_params['config']['port']
    assert_equal chan.user, @smpp_params['config']['user']
    assert_equal chan.password, @smpp_params['config']['password']
    assert_equal chan.system_type, @smpp_params['config']['system_type']
    assert_equal chan.source_ton, @smpp_params['config']['source_ton']
    assert_equal chan.source_npi, @smpp_params['config']['source_npi']
    assert_equal chan.destination_ton, @smpp_params['config']['destination_ton']
    assert_equal chan.destination_npi, @smpp_params['config']['destination_npi']
    assert_equal chan.endianness_mo, @smpp_params['config']['endianness_mo']
    assert_equal chan.endianness_mt, @smpp_params['config']['endianness_mt']
    assert_equal chan.accept_mo_hex_string, @smpp_params['config']['accept_mo_hex_string']
    assert_equal chan.default_mo_encoding, @smpp_params['config']['default_mo_encoding']
    assert_equal chan.mt_encodings, @smpp_params['config']['mt_encodings']
    assert_equal chan.mt_max_length, @smpp_params['config']['mt_max_length']
    assert_equal chan.mt_csms_method, @smpp_params['config']['mt_csms_method']
    assert_equal chan.suspension_codes, @smpp_params['config']['suspension_codes']
    assert_equal chan.rejection_codes, @smpp_params['config']['rejection_codes']
  end

  test "updates Twilio channel" do
    post :create, @twilio_params
    chan = Channel.all[0]
    twilio_config_v2 = { "account_sid" => "545454_v2", "auth_token" => "656565_v2", "from" => "123456782" }

    post :update, :config => twilio_config_v2, :id => chan.name
    chan = Channel.all[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, TwilioChannel.default_protocol

    assert_equal chan.account_sid, twilio_config_v2["account_sid"]
    assert_equal chan.auth_token, twilio_config_v2["auth_token"]
    assert_equal chan.from, twilio_config_v2["from"]
  end

  test "updates Chikka channel" do
    post :create, @chikka_params
    chan = Channel.all[0]
    chikka_config_v2 = { "shortcode" => "545454_v2", "client_id" => "272", "secret_key" => "656565_v2", "secret_token" => "36d0efv2" }

    post :update, :config => chikka_config_v2, :id => chan.name
    chan = Channel.all[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, ChikkaChannel.default_protocol

    assert_equal chan.shortcode, chikka_config_v2["shortcode"]
    assert_equal chan.client_id, chikka_config_v2["client_id"]
    assert_equal chan.secret_key, chikka_config_v2["secret_key"]
    assert_equal chan.secret_token, chikka_config_v2["secret_token"]
  end

  test "updates AfricasTalking channel" do
    post :create, @africas_talking_params
    chan = Channel.all[0]
    africas_talking_config_v2 = { "username" => "johny doe", "api_key" => "55ee11ff_v2", "shortcode" => "545454_v2", "secret_token" => "36d0efv2", "use_sandbox" => "0" }

    post :update, :config => africas_talking_config_v2, :id => chan.name
    chan = Channel.all[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, AfricasTalkingChannel.default_protocol

    assert_equal chan.username, africas_talking_config_v2['username']
    assert_equal chan.api_key, africas_talking_config_v2['api_key']
    assert_equal chan.shortcode, africas_talking_config_v2['shortcode']
    assert_equal chan.secret_token, africas_talking_config_v2['secret_token']
    assert_equal chan.use_sandbox, africas_talking_config_v2['use_sandbox']
  end

  test "updates SMPP channel" do
    post :create, @smpp_params
    chan = Channel.all[0]
    smpp_config_v2 = { "host" => "nexmo_v2", "port" => "8081", "user" => "johny doe", "password" => "1234567", "system_type" =>  "vma_2", "source_ton" => "2", "source_npi" => "3", "destination_ton" => "4", "destination_npi" => "5", "endianness_mo" => "big", "endianness_mt" => "little", "accept_mo_hex_string" => "0", "default_mo_encoding" => "latin1", "mt_encodings" => ["latin1"], "mt_max_length" => "160", "mt_csms_method" => "optional_parameters", "suspension_codes" => ["c1"], "rejection_codes" => ["c2"] }

    post :update, :config => smpp_config_v2, :id => chan.name
    chan = Channel.all[0]

    assert_equal @account.id, chan.account_id
    assert_equal chan.direction, Channel::Bidirectional
    assert_equal chan.protocol, SmppChannel.default_protocol

    assert_equal chan.host, smpp_config_v2['host']
    assert_equal chan.port, smpp_config_v2['port']
    assert_equal chan.user, smpp_config_v2['user']
    assert_equal chan.password, smpp_config_v2['password']
    assert_equal chan.system_type, smpp_config_v2['system_type']
    assert_equal chan.source_ton, smpp_config_v2['source_ton']
    assert_equal chan.source_npi, smpp_config_v2['source_npi']
    assert_equal chan.destination_ton, smpp_config_v2['destination_ton']
    assert_equal chan.destination_npi, smpp_config_v2['destination_npi']
    assert_equal chan.endianness_mo, smpp_config_v2['endianness_mo']
    assert_equal chan.endianness_mt, smpp_config_v2['endianness_mt']
    assert_equal chan.accept_mo_hex_string, smpp_config_v2['accept_mo_hex_string']
    assert_equal chan.default_mo_encoding, smpp_config_v2['default_mo_encoding']
    assert_equal chan.mt_encodings, smpp_config_v2['mt_encodings']
    assert_equal chan.mt_max_length, smpp_config_v2['mt_max_length']
    assert_equal chan.mt_csms_method, smpp_config_v2['mt_csms_method']
    assert_equal chan.suspension_codes, smpp_config_v2['suspension_codes']
    assert_equal chan.rejection_codes, smpp_config_v2['rejection_codes']
	end

  test "doesn't update channels name despite being included in the params" do
    post :create, @twilio_params
    chan = Channel.all[0]
    previous_name = chan.name
    params = { "name" => "foobar", "account_sid" => "545454_v2", "auth_token" => "656565_v2", "from" => "123456782" }

    post :update, :config => params, :id => chan.name
    chan = Channel.all[0]

    assert_equal chan.name, previous_name
  end
end
