require 'test_helper'

class ApiChannelControllerTest < ActionController::TestCase

  def setup
    @account = Account.create! :name => 'acc', :password => 'acc_pass'
    @application = create_app @account
    @application2 = create_app @account, 10
    
    account2 = Account.create! :name => 'acc2', :password => 'acc_pass'
    app2 = create_app account2
    
    chan2 = new_channel account2, 'foobar'
    chan3 = new_channel @account, 'other-chan', :application_id => @application2.id
  end
  
  def index(format, result_channel_count)
    yield if block_given?
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    get :index, :format => format
    
    case format
    when 'xml'
      xml = Hash.from_xml(@response.body).with_indifferent_access
      chans = xml[:channels]
      if result_channel_count == 0
        assert_nil chans
      else
        assert_equal result_channel_count, chans[:channel].length
      end
    when 'json'
      json = JSON.parse @response.body
      assert_equal result_channel_count, json.length
    end
  end
  
  def show(name, format, result_channel_count)
    yield if block_given?
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    get :show, :format => format, :name => name
    return assert_response :not_found if result_channel_count == 0
    assert_response :ok
    
    case format
    when 'xml'
      xml = Hash.from_xml(@response.body).with_indifferent_access
      assert_not_nil xml[:channel]
    when 'json'
      json = JSON.parse @response.body
      assert_not_nil json
    end
  end
  
  def update(name, channel, format)
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    @request.env['RAW_POST_DATA'] = channel.send("to_#{format}", :include_passwords => true)
    
    put :update, :format => format, :name => name
    
    assert_response :ok
  end
  
  def create(channel, format, expected_response = :ok)
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    @request.env['RAW_POST_DATA'] = channel.send("to_#{format}", :include_passwords => true)
    
    post :create, :format => format
    
    assert_response expected_response
  end
  
  ['json', 'xml'].each do |format|
    test "index #{format} no channels" do
      index format, 0
    end
    
    test "index #{format} two channels" do
      index format, 2 do
        2.times {|i| new_channel @account, "chan#{i}", :application_id => @application.id }
      end
    end
    
    test "index #{format} should also include channels that don't belong to any application" do
      index format, 3 do
        2.times {|i| new_channel @account, "chan#{i}", :application_id => @application.id }
        new_channel @account, "chan3"
      end
    end
    
    test "show #{format} not found" do
      show 'hola', format, 0
    end
    
    test "show #{format} for application found" do
      show 'hola', format, 1 do
        new_channel @account, "hola", :application_id => @application.id
      end
    end
    
    test "show #{format} for no application found" do
      show 'hola', format, 1 do
        chan = new_channel @account, "hola"
      end
    end
    
    test "create #{format} channel succeeds" do
      chan = Channel.new(:name => 'new_chan', :kind => 'qst_client', :protocol => 'sms', :direction => Channel::Bidirectional, :enabled => false, :priority => 2);
      chan.configuration = {:url => 'a', :user => 'b', :password => 'c'};
      chan.restrictions['foo'] = ['a', 'b', 'c']
      chan.restrictions['bar'] = 'baz'
      
      create chan, format
      
      result = @account.channels.last
      
      assert_not_nil result
      assert_equal @account.id, result.account_id
      assert_equal @application.id, result.application_id
      [:name, :kind, :protocol, :direction, :enabled, :priority, :restrictions, :configuration].each do |sym|
        assert_equal chan.send(sym), result.send(sym)
      end
    end
    
    test "create #{format} channel fails missing name" do
      chan = Channel.new(:kind => 'qst_server', :protocol => 'sms', :direction => Channel::Bidirectional);
      chan.configuration = {:password => 'c'};
      
      before_count = Channel.all.length      
      create chan, format, :bad_request      
      assert_equal before_count, Channel.all.length
      
      errors = (format == 'xml' ? Hash.from_xml(@response.body) : JSON.parse(@response.body)).with_indifferent_access
      if format == 'xml'
        assert_not_nil errors[:error][:summary]
        assert_equal "name", errors[:error][:property][:name]
        assert_not_nil errors[:error][:property][:value]
      else
        assert_not_nil errors[:summary]
        assert_equal "name", errors[:properties][0].keys[0]
        assert_not_nil errors[:properties][0].values[0]
      end
    end
    
    test "update #{format} channel succeeds" do
      chan = new_channel @account, "chan_foo", :application_id => @application.id, :priority => 20
      update 'chan_foo', Channel.new(:protocol => 'foobar', :priority => nil), format
      chan.reload
      
      assert_equal 'foobar', chan.protocol
      assert_equal 20, chan.priority
    end
    
    test "update #{format} channel configuration succeeds" do
      chan = new_channel @account, "chan_foo", :application_id => @application.id
      update 'chan_foo', Channel.new(:configuration => {:url => 'x', :user => 'y', :password => 'z'}), format
      chan.reload
      
      assert_equal 'x', chan.configuration[:url]
      assert_equal 'y', chan.configuration[:user]
    end
    
    test "update #{format} channel restrictions succeeds" do
      chan = new_channel @account, "chan_foo", :application_id => @application.id
      update 'chan_foo', Channel.new(:restrictions => {'x' => 'z'}), format
      chan.reload
      
      assert_equal 'z', chan.restrictions['x']
    end
  end
  
  test "update channel fails no channel found" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    put :update, :format => 'xml', :name => "chan_lala"
    assert_response :bad_request
  end
  
  test "update channel fails not owner" do
    new_channel @account, "chan_foo"
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    put :update, :format => 'xml', :name => "chan_foo"
    assert_response :bad_request
  end
  
  test "delete channel succeeds" do
    new_channel @account, "chan_foo", :application_id => @application.id
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    delete :destroy, :name => "chan_foo"
    assert_response :ok
    
    assert_nil @account.find_channel "chan_foo"
  end
  
  test "delete channel fails, no channel found" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    delete :destroy, :name => "chan_lala"
    assert_response :bad_request
  end
  
  test "delete channel fails, does not own channel" do
    new_channel @account, "chan_foo"
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    delete :destroy, :name => "chan_foo"
    assert_response :bad_request
  end

end
