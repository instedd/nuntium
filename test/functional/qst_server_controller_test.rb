require 'test_helper'

class QstServerControllerTest < ActionController::TestCase
  def setup
    @account = Account.make :password
    @chan = QstServerChannel.make_unsaved :account => @account
    @chan.configuration[:password] = 'chan_pass'
    @chan.configuration[:password_confirmation] = 'chan_pass'
    @chan.configuration.delete :salt
    @chan.save!

    @application1 = Application.make :account => @account

    # This is so that we have another channel but the one we are looking for is used
    QstServerChannel.make :account => @account

    # This is to see that this doesn't interfere with the test
    @account2 = Account.make
    @chan2 = QstServerChannel.make :account => @account2
    @application2 = Application.make :account => @account2
  end

  test "set address" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'chan_pass'

    get :set_address, :address => 'foo', :account_id => @chan.account.name

    @chan.reload
    assert_equal 'foo', @chan.address
  end

  def get_last_id(expected)
    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'chan_pass'
    head :get_last_id, :account_id => @account.name
    assert_response :ok

    assert_equal expected, @response.headers['Etag']
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

  test "get last message id updates channel's last activity at" do
    get_last_id ""

    @chan.reload
    assert_in_delta Time.now.utc, @chan.last_activity_at, 5
  end

  test "can't read" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'chan_pass'
    get :get_last_id, :account_id => @account.name
    assert_response :not_found
  end

  def push(data)
    @request.env['RAW_POST_DATA'] = data.strip

    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'chan_pass'
    post :push, :account_id => @account.name
    assert_response :ok

    messages = AtMessage.all
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

    assert_equal msg.guid.to_s, @response.headers['Etag']

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

  test "push messages updates channel's last activity at" do
    msg = push <<-eos
      <?xml version="1.0" encoding="utf-8"?>
      <messages>
        <message id="someguid" from="Someone" to="Someone else" when="2008-09-24T17:12:57-03:00">
          <text>Hello!</text>
        </message>
      </messages>
    eos

    @chan.reload
    assert_in_delta Time.now.utc, @chan.last_activity_at, 5
  end

  test "get last message id not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'wrong_chan_pass'
    head :get_last_id, :account_id => @account.name
    assert_response 401
  end

  test "push messages not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'wrong_chan_pass'
    post :push, :account_id => @account.name
    assert_response 401
  end

  def create_qst_ao(account, channel)
    msg = AoMessage.make :account => account, :channel => channel, :state => 'queued'
    QstOutgoingMessage.create! :channel => channel, :ao_message_id => msg.id
    msg
  end

  test "get updates channel's last activity at" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'chan_pass'
    get :pull, :account_id => @account.name

    @chan.reload
    assert_in_delta Time.now.utc, @chan.last_activity_at, 5
  end

  test "get one" do
    msg2 = create_qst_ao @account2, @chan2
    msg = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth @chan.name, 'chan_pass'
    get :pull, :account_id => @account.name

    assert_equal msg.id.to_s, @response.headers['Etag']

    assert_select "message", {:count => 1}
    assert_shows_message msg

    unread = QstOutgoingMessage.all
    assert_equal 2, unread.length

    assert_equal @chan2.id, unread[0].channel_id
    assert_equal msg2.id, unread[0].ao_message_id

    assert_equal @chan.id, unread[1].channel_id
    assert_equal msg.id, unread[1].ao_message_id

    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid
    get :pull, :account_id => @account.name

    assert_select "message", {:count => 0}
  end

  test "get one with custom properties" do
    msg = AoMessage.make_unsaved :account => @account
    msg.custom_attributes['foo1'] = 'bar1'
    msg.custom_attributes['foo2'] = 'bar2'
    msg.save!

    QstOutgoingMessage.create! :channel => @chan, :ao_message_id => msg.id

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    get :pull, :account_id => @account.name

    assert_select "message", {:count => 1}
    assert_shows_message msg
  end

  test "get one not unread" do
    AoMessage.make :account => @account

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    get :pull, :account_id => @account.name
    assert_select "message", {:count => 0}
  end

  test "get one increments retires" do
    msg = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')

    1.upto 3 do |i|
      get :pull, :account_id => @account.name
      assert_select "message", {:count => 1}
      assert_equal i, AoMessage.first.tries
    end

    # Try number 4 -> should be gone
    get :pull, :account_id => @account.name
    assert_select "message", {:count => 0}
    assert_equal 'failed', AoMessage.first.state
  end

  test "should return not modified for HTTP_IF_NONE_MATCH" do
    msg2 = create_qst_ao @account2, @chan2
    msg0 = create_qst_ao @account, @chan
    msg1 = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msg1.guid
    get :pull, :account_id => @account.name

    assert_select "message", {:count => 0}

    unread = QstOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal @chan2.id, unread[0].channel_id
    assert_equal msg2.id, unread[0].ao_message_id
  end

  test "should apply HTTP_IF_NONE_MATCH" do
    msg0 = create_qst_ao @account, @chan
    msg1 = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msg0.guid
    get :pull, :account_id => @account.name

    assert_equal msg1.id.to_s, @response.headers['Etag']

    assert_select "message", {:count => 1}
    assert_shows_message msg1

    # One unread message was deleted
    unread = QstOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal msg1.id, unread[0].ao_message_id

    # The first message is marked as delivered,
    # the second stays as queued
    msgs = AoMessage.all

    assert_equal 'delivered', msgs[0].state
    assert_equal 'queued', msgs[1].state
  end

  test "should apply HTTP_IF_NONE_MATCH with max" do
    msgs = 4.times.map{ create_qst_ao(@account, @chan) }

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msgs[1].guid.to_s
    get :pull, :account_id => @account.name, :max => 1

    assert_equal msgs[2].id.to_s, @response.headers['Etag']

    assert_select "message", {:count => 1}
    assert_shows_message msgs[2]

    unread = QstOutgoingMessage.all
    assert_equal 2, unread.length
    assert_equal msgs[2].id, unread[0].ao_message_id
    assert_equal msgs[3].id, unread[1].ao_message_id
  end

  test "get not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'wrong_pass')
    get :pull, :account_id => @account.name

    assert_response 401
  end

  test "should apply HTTP_IF_NONE_MATCH real example" do
    # First
    msg = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    get :pull, :account_id => @account.name

    assert_equal msg.id.to_s, @response.headers['Etag']

    assert_select "message", {:count => 1}
    assert_shows_message msg

    # Second
    msg1 = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid.to_s
    get :pull, :account_id => @account.name

    assert_equal msg1.id.to_s, @response.headers['Etag']

    assert_select "message", {:count => 1}
    assert_shows_message msg1
  end

  test "should skip failed messages" do
    10.times do |i|
      msg = AoMessage.make :account => @account, :tries => 4
      QstOutgoingMessage.create! :channel => @chan, :ao_message_id => msg.id
    end

    msg11 = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    get :pull, :account_id => @account.name

    assert_equal msg11.id.to_s, @response.headers['Etag']

    assert_select "message", {:count => 1}
    assert_shows_message msg11

    # One unread message
    unread = QstOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal msg11.id, unread[0].ao_message_id
  end

  test "should work if HTTP_IF_NONE_MATCH is not found" do
    msg = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = "someguid 3"
    get :pull, :account_id => @account.name

    assert_equal msg.id.to_s, @response.headers['Etag']

    assert_select "message", {:count => 1}
    assert_shows_message msg

    unread = QstOutgoingMessage.all
    assert_equal 1, unread.length
  end

  test "bug update wrong ao messages" do
    msg2 = create_qst_ao @account2, @chan2

    original_state = msg2.state

    msg = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid
    get :pull, :account_id => @account.name

    assert_equal original_state, AoMessage.find(msg2.id).state
  end

  test "get one decrements queued ao count" do
    msg = create_qst_ao @account, @chan

    assert_equal 1, @chan.queued_ao_messages_count

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msg.guid
    get :pull, :account_id => @account.name

    assert_equal 0, @chan.queued_ao_messages_count
  end

  test "don't return cancelled messages" do
    msg = create_qst_ao @account, @chan
    msg.state = 'cancelled'
    msg.save!

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    get :pull, :account_id => @account.name

    assert_select "message", {:count => 0}
  end

  test "don't mark cancelled messages as delivered" do
    msg1 = create_qst_ao @account, @chan
    msg1.state = 'cancelled'
    msg1.save!

    msg2 = create_qst_ao @account, @chan

    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'chan_pass')
    @request.env["HTTP_IF_NONE_MATCH"] = msg1.guid
    get :pull, :account_id => @account.name

    assert_select "message", {:count => 1}
    assert_equal 1, QstOutgoingMessage.count

    msg1.reload
    assert_equal 'cancelled', msg1.state
  end

  def assert_shows_message(msg)
    assert_select "message[id=?]", msg.guid
    assert_select "message[from=?]", msg.from
    assert_select "message[to=?]", msg.to
    assert_select "message[when=?]", msg.timestamp.iso8601
    assert_select "message text", msg.subject.nil? ? msg.body : msg.subject + " - " + msg.body

    msg.custom_attributes.each do |name, value|
      assert_select "message property[name=?][value=?]", name, value, :count => 1
    end
  end
end
