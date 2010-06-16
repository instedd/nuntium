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
      
      assert_equal @account.id, msg.account_id
      assert_equal "s", msg.subject
      assert_equal "b", msg.body
      assert_equal "sms://1234", msg.from
      assert_equal to, msg.to
      assert_equal "g", msg.guid
      assert_not_nil msg.timestamp
      assert_equal (ok ? 'queued' : 'failed'), msg.state
      assert_equal (ok ? @chan.id : nil), msg.channel_id
    end
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

end
