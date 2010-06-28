require 'test_helper'

class ClickatellControllerTest < ActionController::TestCase
  tests ClickatellController
  
  def setup
    @account = Account.make
    @application = Application.make :account => @account, :password => 'secret'
    @chan = Channel.make_unsaved :clickatell, :account => @account
    @chan.configuration[:incoming_password] = 'incoming'
    @chan.save!
  end
  
  def assert_message(options = {})
    assert_equal 0, ClickatellMessagePart.all.length
    
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    
    msg = msgs[0]
    assert_equal @account.id, msg.account_id
    assert_equal "sms://#{options[:from]}", msg.from
    assert_equal "sms://#{options[:to]}", msg.to
    assert_equal options[:body], msg.body
    assert_equal Time.parse('2009-12-16 17:34:40 UTC'), msg.timestamp
    assert_equal options[:channel_relative_id], msg.channel_relative_id
    assert_equal 'queued', msg.state
    assert_not_nil msg.guid
  end

  test "index" do
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id],  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '', 'some text', '5223433'
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming')
    
    get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok
    
    assert_message :from => from, :to => to, :body => text, :channel_relative_id => mo_msg_id
  end
  
  [:normal_order, :inverted_order].each do |order|
    test "two parts #{order}" do
      from, to = '442345235413', '61234234231'
      @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming')
      
      2.times do |time|
        if (time == 0 and order == :normal_order) or (time == 1 and order == :inverted_order) 
          api_id, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id], '2009-12-16 19:34:40', 'ISO-8859-1', '050003050201', 'Hello ', '1'
          get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
          assert_response :ok
        else
          api_id, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id], '2009-12-16 19:34:40', 'ISO-8859-1', '050003050202', 'world', '2'
          get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
          assert_response :ok
        end
      end
      
      assert_message :from => from, :to => to, :body => 'Hello world', :channel_relative_id => (order == :normal_order ? '2' : '1')
    end
  end
  
  test "ignore message headers" do
    api_id, from, to, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id],  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050103050202', 'Hello ', '1'
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming')
    get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok

    api_id, from, to, timestamp, charset, udh, text, mo_msg_id = @chan.configuration[:api_id],  '442345235413', '61234234231', '2009-12-16 19:34:40', 'ISO-8859-1', '050103050201', 'world', '1'
    get :index, :account_id => @account.name, :api_id => api_id, :from => from, :to => to, :text => text, :timestamp => timestamp, :charset => charset, :moMsgId => mo_msg_id, :udh => udh
    assert_response :ok
        
    assert_equal 0, ClickatellMessagePart.all.length
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
  end
  
  test "fails authorization because of account" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming')
    get :index, :account_id => 'another', :api_id => @chan.configuration[:api_id], :from => 'from1', :to => 'to1', :text => 'some text', :timestamp => '1218007814', :charset => 'UTF-8', :moMsgId => 'someid'
    assert_response 401
    
    assert_equal 0, ATMessage.count    
  end
  
  test "fails authorization because of channel" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@chan.name, 'incoming2')
    get :index, :account_id => @account.name, :api_id => @chan.configuration[:api_id], :from => 'from1', :to => 'to1', :text => 'some text', :timestamp => '1218007814', :charset => 'UTF-8', :moMsgId => 'someid'
    assert_response 401
    
    assert_equal 0, ATMessage.count
  end

end
