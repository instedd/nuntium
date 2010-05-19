require 'test_helper'

class ApiChannelControllerTest < ActionController::TestCase

  def setup
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret'
    @application2 = Application.make :account => @account
    
    account2 = Account.make
    app2 = Application.make :account => account2
    
    chan2 = Channel.make :account => account2
    chan3 = Channel.make :account => @account, :application => @application2
  end
  
  def authorize
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret')
  end
  
  def index(format, result_channel_count)
    yield if block_given?
    
    authorize
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
    
    authorize
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
    authorize
    @request.env['RAW_POST_DATA'] = channel.send("to_#{format}", :include_passwords => true)
    
    put :update, :format => format, :name => name
    
    assert_response :ok
  end
  
  def create(channel, format, expected_response = :ok)
    authorize
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
        2.times {|i| Channel.make :account => @account, :application => @application }
      end
    end
    
    test "index #{format} should also include channels that don't belong to any application" do
      index format, 3 do
        2.times {|i| Channel.make :account => @account, :application => @application }
        Channel.make :account => @account
      end
    end
    
    test "show #{format} not found" do
      show 'hola', format, 0
    end
    
    test "show #{format} for application found" do
      show 'hola', format, 1 do
        Channel.make :account => @account, :application => @application, :name => 'hola'
      end
    end
    
    test "show #{format} for no application found" do
      show 'hola', format, 1 do
        Channel.make :account => @account, :name => 'hola'
      end
    end
    
    test "create #{format} channel succeeds" do
      chan = Channel.make_unsaved :qst_client, :enabled => false
      chan.restrictions['foo'] = ['a', 'b', 'c']
      chan.restrictions['bar'] = 'baz'
      
      create chan, format
      
      result = @account.channels.last
      
      assert_not_nil result
      assert_equal @account.id, result.account_id
      assert_equal @application.id, result.application_id
      [:name, :kind, :protocol, :direction, :enabled, :priority, :restrictions, :configuration].each do |sym|
        assert_equal chan.send(sym), result.send(sym), "sym was not the same"
      end
    end
    
    test "create #{format} channel fails missing name" do
      chan = Channel.make_unsaved :qst_server, :name => nil
      
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
      chan = Channel.make :account => @account, :application => @application, :priority => 20
      update chan.name, Channel.new(:protocol => 'foobar', :priority => nil), format
      chan.reload
      
      assert_equal 'foobar', chan.protocol
      assert_equal 20, chan.priority
    end
    
    test "update #{format} channel configuration succeeds" do
      chan = Channel.make :qst_client, :account => @account, :application => @application
      update chan.name, Channel.new(:configuration => {:url => 'x', :user => 'y', :password => 'z'}), format
      chan.reload
      
      assert_equal 'x', chan.configuration[:url]
      assert_equal 'y', chan.configuration[:user]
    end
    
    test "update #{format} channel restrictions succeeds" do
      chan = Channel.make :account => @account, :application => @application
      update chan.name, Channel.new(:restrictions => {'x' => 'z'}), format
      chan.reload
      
      assert_equal 'z', chan.restrictions['x']
    end
  end
  
  test "update channel fails no channel found" do
    authorize
    put :update, :format => 'xml', :name => "chan_lala"
    assert_response :bad_request
  end
  
  test "update channel fails not owner" do
    chan = Channel.make :account => @account
    
    authorize
    put :update, :format => 'xml', :name => chan.name
    assert_response :bad_request
  end
  
  test "delete channel succeeds" do
    chan = Channel.make :account => @account, :application => @application
    
    authorize
    delete :destroy, :name => chan.name
    assert_response :ok
    
    assert_nil @account.find_channel chan.name
  end
  
  test "delete channel fails, no channel found" do
    authorize
    delete :destroy, :name => "chan_lala"
    assert_response :bad_request
  end
  
  test "delete channel fails, does not own channel" do
    chan = Channel.make :account => @account
    
    authorize
    delete :destroy, :name => chan.name
    assert_response :bad_request
  end

end
