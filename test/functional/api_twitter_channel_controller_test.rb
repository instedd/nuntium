require 'test_helper'

class ApiTwitterChannelControllerTest < ActionController::TestCase

  include Mocha::API

  [nil, false, true].each do |follow|
    test "account authenticated with follow #{follow}" do
      @account = Account.make :password => 'secret'    
      @channel = Channel.make :twitter, :account => @account
      
      result = {'result' => 1}
      
      client = mock('client')
      client.expects(:friendship_create).with('foo', follow.to_b).returns(result)
      
      TwitterChannelHandler.expects(:new_client).with(@channel.configuration).returns(client)
      
      @request.env['HTTP_AUTHORIZATION'] = http_auth(@account.name, 'secret')
      get :friendship_create, :name => @channel.name, :user => 'foo', :follow => follow
      
      assert_response :ok
      got = JSON.parse @response.body
      
      assert_equal result, got
    end
  end
  
  test "application authenticated" do
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret2'
    @channel = Channel.make :twitter, :account => @account, :application => @application
    
    result = {'result' => 1}
    
    client = mock('client')
    client.expects(:friendship_create).with('foo', false).returns(result)
    
    TwitterChannelHandler.expects(:new_client).with(@channel.configuration).returns(client)
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret2')
    get :friendship_create, :name => @channel.name, :user => 'foo'
    
    assert_response :ok
    got = JSON.parse @response.body
    
    assert_equal result, got
  end
  
  test "application authenticated can't access account channel" do
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret2'
    @channel = Channel.make :twitter, :account => @account
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret2')
    get :friendship_create, :name => @channel.name, :user => 'foo'
    
    assert_response :forbidden
  end
  
  test "channel not found" do
    @account = Account.make :password => 'secret'
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@account.name, 'secret')
    get :friendship_create, :name => 'not_exists', :user => 'foo'
    
    assert_response :not_found
  end
  
  test "channel not twitter" do
    @account = Account.make :password => 'secret'
    @channel = Channel.make :qst_server, :account => @account
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth(@account.name, 'secret')
    get :friendship_create, :name => @channel.name, :user => 'foo'
    
    assert_response :bad_request
  end
  
end
