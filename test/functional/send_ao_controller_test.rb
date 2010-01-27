require 'test_helper'

class SendAoControllerTest < ActionController::TestCase

  test "send ao" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server', 'sms')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    get :create, {:from => 'sms://1234', :to => 'sms://5678', :subject => 's', :body => 'b', :guid => 'g'}
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_equal 'id: ' + msg.id.to_s, @response.body
    
    assert_equal app.id, msg.application_id
    assert_equal "s", msg.subject
    assert_equal "b", msg.body
    assert_equal "sms://1234", msg.from
    assert_equal "sms://5678", msg.to
    assert_equal "g", msg.guid
    assert_not_nil msg.timestamp
    assert_equal 'queued', msg.state
    assert_equal chan.id, msg.channel_id
  end
  
  test "send ao error" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server', 'sms')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    get :create, {:from => 'sms://1234', :to => 'PROT://5678', :subject => 's', :body => 'b', :guid => 'g'}
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_equal 'error: ' + msg.id.to_s, @response.body
    
    assert_equal app.id, msg.application_id
    assert_equal "s", msg.subject
    assert_equal "b", msg.body
    assert_equal "sms://1234", msg.from
    assert_equal "PROT://5678", msg.to
    assert_equal "g", msg.guid
    assert_not_nil msg.timestamp
    assert_equal 'error', msg.state
    assert_nil msg.channel_id
  end
  
  test "send ao error without to" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server', 'sms')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'app_pass')
    get :create, {:from => 'sms://1234', :subject => 's', :body => 'b', :guid => 'g'}
    
    messages = AOMessage.all
    assert_equal 1, messages.length
    
    msg = messages[0]
    
    assert_equal 'error: ' + msg.id.to_s, @response.body
    
    assert_equal app.id, msg.application_id
    assert_equal "s", msg.subject
    assert_equal "b", msg.body
    assert_equal "sms://1234", msg.from
    assert_equal nil, msg.to
    assert_equal "g", msg.guid
    assert_not_nil msg.timestamp
    assert_equal 'error', msg.state
    assert_nil msg.channel_id
  end
  
  test "send ao fails not authorized" do
    app, chan = create_app_and_channel('app', 'app_pass', 'chan', 'chan_pass', 'qst_server', 'sms')
  
    @request.env['HTTP_AUTHORIZATION'] = http_auth('app', 'wrong_pass')
    get :create, {:from => 'sms://1234', :to => 'sms://5678', :subject => 's', :body => 'b', :guid => 'g'}
    
    assert_response 401
    
    messages = AOMessage.all
    assert_equal 0, messages.length
  end

end