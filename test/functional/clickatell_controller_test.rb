require 'test_helper'

class ClickatellControllerTest < ActionController::TestCase
  tests ClickatellController

  test "index" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => '1034412', :incoming_password => 'incoming' }
    chan.save
    
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id =  '1034412',  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '', 'some text', '5223433'
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    
    get :index, :application_id => app.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    
    assert_equal 0, ClickatellMessagePart.all.length
    
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    
    msg = msgs[0]
    assert_equal app.id, msg.application_id
    assert_equal 'sms://' + from, msg.from
    assert_equal 'sms://' + to, msg.to
    assert_equal text, msg.subject
    assert_equal Time.parse('2009-12-16 17:34:40 UTC'), msg.timestamp
    assert_equal mo_msg_id, msg.channel_relative_id
    assert_equal 'queued', msg.state
    assert_not_nil msg.guid
    
    assert_response :ok
  end
  
  test "two parts" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => '1034412', :incoming_password => 'incoming' }
    chan.save
    
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id =  '1034412',  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050003050201', 'Hello ', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => app.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok
    
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id =  '1034412',  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050003050202', 'world', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => app.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok
    
    assert_equal 0, ClickatellMessagePart.all.length
    
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    
    msg = msgs[0]
    assert_equal app.id, msg.application_id
    assert_equal 'sms://' + from, msg.from
    assert_equal 'sms://' + to, msg.to
    assert_equal 'Hello world', msg.subject
    assert_equal Time.parse('2009-12-16 17:34:40 UTC'), msg.timestamp
    assert_equal '1', msg.channel_relative_id
    assert_equal 'queued', msg.state
    assert_not_nil msg.guid
  end
  
  test "two parts other order" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => '1034412', :incoming_password => 'incoming' }
    chan.save
    
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id =  '1034412',  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050003050202', 'world', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => app.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok
    
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id =  '1034412',  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050003050201', 'Hello ', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => app.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok
    
    assert_equal 0, ClickatellMessagePart.all.length
    
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    
    msg = msgs[0]
    assert_equal app.id, msg.application_id
    assert_equal 'sms://' + from, msg.from
    assert_equal 'sms://' + to, msg.to
    assert_equal 'Hello world', msg.subject
    assert_equal Time.parse('2009-12-16 17:34:40 UTC'), msg.timestamp
    assert_equal '1', msg.channel_relative_id
    assert_equal 'queued', msg.state
    assert_not_nil msg.guid
  end
  
  test "ignore message headers" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => '1034412', :incoming_password => 'incoming' }
    chan.save
    
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id =  '1034412',  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050103050202', 'Hello ', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => app.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok

    api_id, from, to, timestamp, charset, udh, text, mo_msg_id =  '1034412',  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050103050201', 'world', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => app.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok
        
    assert_equal 0, ClickatellMessagePart.all.length
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
  end
  
  test "fails authorization because of application" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :incoming_password => 'incoming' }
    chan.save
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => 'another', :api_id => 'api_id', :from => 'from1', :to => 'to1', :text => 'some text', :timestamp => '1218007814', :charset => 'UTF-8', :moMsgId => 'someid'
    
    msgs = ATMessage.all
    assert_equal 0, msgs.length
    
    assert_response 401
  end
  
  test "fails authorization because of channel" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :incoming_password => 'incoming' }
    chan.save
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming2')
    get :index, :application_id => app.name, :api_id => 'api_id', :from => 'from1', :to => 'to1', :text => 'some text', :timestamp => '1218007814', :charset => 'UTF-8', :moMsgId => 'someid'
    
    msgs = ATMessage.all
    assert_equal 0, msgs.length
    
    assert_response 401
  end

end