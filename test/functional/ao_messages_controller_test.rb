require 'test_helper'

class AoMessagesControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @chan = QstServerChannel.make :account => @account
    @application = Application.make :account => @account, :password => 'app_pass'

    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
  end

  def create_test_ao_messages
    @ao_msg1 = AoMessage.create! :account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'one', :to => 'sms://1'
    @ao_msg2 = AoMessage.create! :account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'one', :to => 'sms://1'
    @ao_msg3 = AoMessage.create! :account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'two', :to => 'sms://1', :tries => 3
  end

  test "get ao as json no matches" do
    get :get_ao, :account_name => @account.name, :application_name => @application.name, :token => '1234', :format => :json

    assert_response :ok

    messages = JSON.parse @response.body
    assert_equal 0, messages.length
  end

  test "get ao as json matches one" do
    token = 1234
    msg = AoMessage.make :account_id => @account.id, :application_id => @application.id, :channel_id => @chan.id, :token => token
    msg.country = 'ar'
    msg.save!

    get :get_ao, :account_name => @account.name, :application_name => @application.name, :token => token, :format => :json

    messages = JSON.parse @response.body
    assert_equal 1, messages.length

    keys = ['from', 'to', 'subject', 'body', 'guid', 'state', 'country']
    assert_equal (keys + ['channel', 'channel_kind']).sort, messages[0].keys.sort
    keys.each do |key|
      assert_equal msg.send(key), messages[0][key]
    end
    assert_equal @chan.name, messages[0]['channel']
    assert_equal @chan.kind, messages[0]['channel_kind']
  end

  def assert_fields(kind, member, *states)
    msgs = (kind == :ao ? AoMessage : AtMessage).all
    assert_equal states.length, msgs.length
    states.length.times do |i|
      assert_equal states[i], msgs[i].send(member)
    end
  end

  test "mark ao messages as cancelled" do
    create_test_ao_messages

    post :mark_as_cancelled, {:ao_messages => [@ao_msg1.id, @ao_msg2.id]}, {:account_id => @account.id}

    assert_redirected_to ao_messages_path(:ao_messages => [@ao_msg1.id, @ao_msg2.id])
    assert_equal '2 Application Originated messages were marked as cancelled', flash[:notice]

    assert_fields :ao, :state, 'cancelled', 'cancelled', 'pending'
  end

  test "mark ao messages as cancelled using search" do
    create_test_ao_messages

    post :mark_as_cancelled, {:ao_all => 1, :search => 'one'}, {:account_id => @account.id}

    assert_redirected_to ao_messages_path(:ao_all => 1, :search => 'one')
    assert_equal '2 Application Originated messages were marked as cancelled', flash[:notice]

    assert_fields :ao, :state, 'cancelled', 'cancelled', 'pending'
  end

  test "re-route ao messages" do
    create_test_ao_messages

    post :reroute, {:ao_messages => [@ao_msg1.id, @ao_msg2.id]}, {:account_id => @account.id}

    assert_redirected_to ao_messages_path(:ao_messages => [@ao_msg1.id, @ao_msg2.id])
    assert_equal '2 Application Originated messages were re-routed', flash[:notice]

    assert_fields :ao, :state, 'queued', 'queued', 'pending'
    assert_fields :ao, :tries, 0, 0, 3
  end

  test "re-route ao messages using search" do
    create_test_ao_messages

    post :reroute, {:ao_all => 1, :search => 'one'}, {:account_id => @account.id}

    assert_redirected_to ao_messages_path(:ao_all => 1, :search => 'one')
    assert_equal '2 Application Originated messages were re-routed', flash[:notice]

    assert_fields :ao, :state, 'queued', 'queued', 'pending'
    assert_fields :ao, :tries, 0, 0, 3
  end

  test "mark ao messages as cancelled decrements queued count" do
    create_test_ao_messages

    @ao_msg1.channel = @chan
    @ao_msg1.state = 'queued'
    @ao_msg1.save!

    assert_equal 1, @account.queued_ao_messages_count_by_channel_id[@chan.id]

    post :mark_as_cancelled, {:ao_messages => [@ao_msg1.id, @ao_msg2.id]}, {:account_id => @account.id}

    assert_equal 0, @account.queued_ao_messages_count_by_channel_id[@chan.id]
  end

  test "mark ao messages as cancelled using search decrements queued count" do
    create_test_ao_messages

    @ao_msg1.channel = @chan
    @ao_msg1.state = 'queued'
    @ao_msg1.save!

    assert_equal 1, @account.queued_ao_messages_count_by_channel_id[@chan.id]

    post :mark_as_cancelled, {:ao_all => 1, :search => 'one'}, {:account_id => @account.id}

    assert_equal 0, @account.queued_ao_messages_count_by_channel_id[@chan.id]
  end

  {nil => false, 'PROT://567' => false, 'sms://5678' => true}.each do |to, ok|
    test "send ao with to = #{to}" do
      get :create_via_api, {:from => 'sms://1234', :to => to, :subject => 's', :body => 'b', :guid => 'g', :account_name => @account.name, :application_name => @application.name}

      messages = AoMessage.all
      assert_equal 1, messages.length

      msg = messages[0]

      assert_equal msg.id.to_s, @response.headers['X-Nuntium-Id']
      assert_equal msg.guid.to_s, @response.headers['X-Nuntium-Guid']
      assert_equal msg.token, @response.headers['X-Nuntium-Token']

      assert_equal @account.id, msg.account_id
      assert_equal "s", msg.subject
      assert_equal "b", msg.body
      assert_equal "sms://1234", msg.from
      assert_equal to, msg.to
      assert_equal "g", msg.guid
      assert_not_nil msg.timestamp
      assert_equal (ok ? 'queued' : 'failed'), msg.state
      assert_equal (ok ? @chan.id : nil), msg.channel_id
      assert_not_nil msg.token
    end
  end

  test "send ao with token" do
    get :create_via_api, {:token => 'my_token', :account_name => @account.name, :application_name => @application.name}

    messages = AoMessage.all
    assert_equal 1, messages.length

    msg = messages[0]

    assert_equal 'my_token', @response.headers['X-Nuntium-Token']

    assert_equal 'my_token', msg.token
  end

  test "send ao can't route but head ok" do
    get :create_via_api, :account_name => @account.name, :application_name => @application.name

    assert_response :ok
  end

  test "send ao fails not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'wrong_pass')
    get :create_via_api, {:from => 'sms://1234', :to => 'sms://5678', :subject => 's', :body => 'b', :guid => 'g', :account_name => @account.name, :application_name => @application.name}

    assert_response 401

    messages = AoMessage.all
    assert_equal 0, messages.length
  end

  test "send ao custom attributes" do
    get :create_via_api, {:from => 'sms://1234', :to => 'sms://5678', :subject => 's', :body => 'b', :guid => 'g', :account_name => @account.name, :application_name => @application.name,
      'foo' => ['bar', 'baz'], 'bax' => 'bex'}

    messages = AoMessage.all
    assert_equal 1, messages.length

    msg = messages[0]
    assert_equal ['bar', 'baz'], msg.custom_attributes['foo']
    assert_equal 'bex', msg.custom_attributes['bax']
  end

  test "send ao with json" do
    @request.env['RAW_POST_DATA'] = [{:from => 'sms://1', :to => 'sms://2', :body => 'foo'}, {:from => 'sms://3', :to => 'sms://4', :body => 'bar'}].to_json

    get :create_via_api, :format => 'json', :account_name => @account.name, :application_name => @application.name

    messages = AoMessage.all
    assert_equal 2, messages.length

    assert_equal messages[0].token, @response.headers['X-Nuntium-Token']

    assert_equal 'sms://1', messages[0].from
    assert_equal 'sms://2', messages[0].to
    assert_equal 'foo', messages[0].body
    assert_equal @chan.id, messages[0].channel_id

    assert_equal 'sms://3', messages[1].from
    assert_equal 'sms://4', messages[1].to
    assert_equal 'bar', messages[1].body
    assert_equal @chan.id, messages[1].channel_id

    assert_not_nil messages[0].token
    assert_not_nil messages[1].token
    assert_equal messages[0].token, messages[1].token
  end

  test "send ao with json and token" do
    @request.env['RAW_POST_DATA'] = [{:token => 'my_token'}].to_json

    get :create_via_api, :format => 'json', :account_name => @account.name, :application_name => @application.name

    messages = AoMessage.all
    assert_equal 1, messages.length

    assert_equal 'my_token', messages[0].token
    assert_equal 'my_token', @response.headers['X-Nuntium-Token']
  end

  test "send ao with xml" do
    msgs = [AoMessage.new(:from => 'sms://1', :to => 'sms://2', :body => 'foo'), AoMessage.new(:from => 'sms://3', :to => 'sms://4', :body => 'bar')]
    @request.env['RAW_POST_DATA'] = AoMessage.write_xml(msgs)

    get :create_via_api, :format => 'xml', :account_name => @account.name, :application_name => @application.name

    messages = AoMessage.all
    assert_equal 2, messages.length

    assert_equal messages[0].token, @response.headers['X-Nuntium-Token']

    assert_equal 'sms://1', messages[0].from
    assert_equal 'sms://2', messages[0].to
    assert_equal 'foo', messages[0].body
    assert_equal @chan.id, messages[0].channel_id

    assert_equal 'sms://3', messages[1].from
    assert_equal 'sms://4', messages[1].to
    assert_equal 'bar', messages[1].body
    assert_equal @chan.id, messages[1].channel_id

    assert_not_nil messages[0].token
    assert_not_nil messages[1].token
    assert_equal messages[0].token, messages[1].token
  end

  test "send ao with xml and token" do
    msgs = [AoMessage.new(:token => 'my_token')]
    @request.env['RAW_POST_DATA'] = AoMessage.write_xml(msgs)

    get :create_via_api, :format => 'xml', :account_name => @account.name, :application_name => @application.name

    messages = AoMessage.all
    assert_equal 1, messages.length

    assert_equal 'my_token', messages[0].token
    assert_equal 'my_token', @response.headers['X-Nuntium-Token']
  end
end
