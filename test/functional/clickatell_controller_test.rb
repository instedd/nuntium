require 'test_helper'

class ClickatellControllerTest < ActionController::TestCase

  test "index" do
    app = Application.create(:name => 'app', :password => 'app_pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'protocol', :direction => Channel::Both)
    chan.configuration = {:user => 'user', :password => 'password', :api_id => 'api_id', :incoming_password => 'incoming' }
    chan.save
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('chan', 'incoming')
    get :index, :application_id => app.name, :api_id => 'api_id', :from => 'from1', :to => 'to1', :text => 'some text', :timestamp => '1218007814', :charset => 'UTF-8', :moMsgId => 'someid'
    
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    
    msg = msgs[0]
    assert_equal app.id, msg.application_id
    assert_equal 'sms://from1', msg.from
    assert_equal 'sms://to1', msg.to
    assert_equal 'some text', msg.subject
    assert_equal Time.at(1218007814), msg.timestamp
    assert_equal 'someid', msg.guid
    assert_equal 'queued', msg.state
    
    assert_response :ok
  end
  
  test "fails authorization because o application" do
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