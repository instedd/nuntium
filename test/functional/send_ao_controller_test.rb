require 'test_helper'

class SendAoControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @chan = Channel.make :account => @account
    @application = Application.make :account => @account, :password => 'app_pass'
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
  end

  {nil => false, 'PROT://567' => false, 'sms://5678' => true}.each do |to, ok|
    test "send ao with to = #{to}" do
      get :create, {:from => 'sms://1234', :to => to, :subject => 's', :body => 'b', :guid => 'g', :account_name => @account.name, :application_name => @application.name}

      messages = AOMessage.all
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
    get :create, {:token => 'my_token', :account_name => @account.name, :application_name => @application.name}

    messages = AOMessage.all
    assert_equal 1, messages.length

    msg = messages[0]

    assert_equal 'my_token', @response.headers['X-Nuntium-Token']

    assert_equal 'my_token', msg.token
  end

  test "send ao can't route but head ok" do
    get :create, :account_name => @account.name, :application_name => @application.name

    assert_response :ok
  end

  test "send ao fails not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'wrong_pass')
    get :create, {:from => 'sms://1234', :to => 'sms://5678', :subject => 's', :body => 'b', :guid => 'g', :account_name => @account.name, :application_name => @application.name}

    assert_response 401

    messages = AOMessage.all
    assert_equal 0, messages.length
  end

  test "send ao custom attributes" do
    get :create, {:from => 'sms://1234', :to => 'sms://5678', :subject => 's', :body => 'b', :guid => 'g', :account_name => @account.name, :application_name => @application.name,
      'foo' => ['bar', 'baz'], 'bax' => 'bex'}

    messages = AOMessage.all
    assert_equal 1, messages.length

    msg = messages[0]
    assert_equal ['bar', 'baz'], msg.custom_attributes['foo']
    assert_equal 'bex', msg.custom_attributes['bax']
  end

  test "send ao with json" do
    @request.env['RAW_POST_DATA'] = [{:from => 'sms://1', :to => 'sms://2', :body => 'foo'}, {:from => 'sms://3', :to => 'sms://4', :body => 'bar'}].to_json

    get :create, :format => 'json', :account_name => @account.name, :application_name => @application.name

    messages = AOMessage.all
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

    get :create, :format => 'json', :account_name => @account.name, :application_name => @application.name

    messages = AOMessage.all
    assert_equal 1, messages.length

    assert_equal 'my_token', messages[0].token
    assert_equal 'my_token', @response.headers['X-Nuntium-Token']
  end

  test "send ao with xml" do
    msgs = [AOMessage.new(:from => 'sms://1', :to => 'sms://2', :body => 'foo'), AOMessage.new(:from => 'sms://3', :to => 'sms://4', :body => 'bar')]
    @request.env['RAW_POST_DATA'] = AOMessage.write_xml(msgs)

    get :create, :format => 'xml', :account_name => @account.name, :application_name => @application.name

    messages = AOMessage.all
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
    msgs = [AOMessage.new(:token => 'my_token')]
    @request.env['RAW_POST_DATA'] = AOMessage.write_xml(msgs)

    get :create, :format => 'xml', :account_name => @account.name, :application_name => @application.name

    messages = AOMessage.all
    assert_equal 1, messages.length

    assert_equal 'my_token', messages[0].token
    assert_equal 'my_token', @response.headers['X-Nuntium-Token']
  end
end
