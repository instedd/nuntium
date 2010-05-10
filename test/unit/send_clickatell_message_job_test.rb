require 'test_helper'
require 'uri'
require 'net/http'
require 'net/https'
require 'mocha'

class SendClickatellMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  should "perform" do
    request = mock('Net::HTTP')
  
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ID: msgid')
      
    host = URI::parse('https://api.clickatell.com')
    
    params = {
      :api_id => 'api1',
      :user => 'user1',
      :password => 'pass1',
      :from => 'someone',
      :mo => '1',
      :to => '5678',
      :text => 'text me'
    }
    uri = "/http/sendmsg?#{params.to_query}"
    
    Net::HTTP.expects(:new).with(host.host, host.port).returns(request)
    request.expects('use_ssl=').with(true)
    request.expects('verify_mode=').with(OpenSSL::SSL::VERIFY_NONE)
    request.expects(:get).with(uri).returns(response)
    
    account = Account.create(:name => 'account', :password => 'pass')
    chan = Channel.new(:account_id => account.id, :name => 'chan', :protocol => 'protocol', :kind => 'clickatell', :direction => Channel::Bidirectional)
    chan.configuration = {:api_id => 'api1', :user => 'user1', :password => 'pass1', :from => 'someone', :incoming_password => 'pass2'}
    assert_true chan.save!
    
    msg = AOMessage.create(:account_id => account.id, :from => 'sms://1234', :to => 'sms://5678', :body => 'text me', :state => 'pending')
      
    job = SendClickatellMessageJob.new(account.id, chan.id, msg.id)
    result = job.perform
    
    msg = AOMessage.first
    assert_equal 'msgid', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
  
  should "perform error" do
    request = mock('Net::HTTP')
  
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ERR: 105, Invalid destination address')
      
    host = URI::parse('https://api.clickatell.com')
    
    params = {
      :api_id => 'api1',
      :user => 'user1',
      :password => 'pass1',
      :from => 'someone',
      :mo => '1',
      :to => '5678',
      :text => 'text me'
    }
    uri = "/http/sendmsg?#{params.to_query}"
    
    Net::HTTP.expects(:new).with(host.host, host.port).returns(request)
    request.expects('use_ssl=').with(true)
    request.expects('verify_mode=').with(OpenSSL::SSL::VERIFY_NONE)
    request.expects(:get).with(uri).returns(response)
    
    account = Account.create(:name => 'account', :password => 'pass')
    chan = Channel.new(:account_id => account.id, :name => 'chan', :protocol => 'protocol', :kind => 'clickatell', :direction => Channel::Bidirectional)
    chan.configuration = {:api_id => 'api1', :user => 'user1', :password => 'pass1', :from => 'someone', :incoming_password => 'pass2'}
    assert_true chan.save!
    
    msg = AOMessage.create(:account_id => account.id, :from => 'sms://1234', :to => 'sms://5678', :body => 'text me', :state => 'queued')
    
    job = SendClickatellMessageJob.new(account.id, chan.id, msg.id)
    result = job.perform
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'queued', msg.state
    
    logs = AccountLog.all
    assert_equal 1, logs.length
    assert_true logs[0].message.include?('105, Invalid destination address')
  end
  
  should "perform fatal error" do
    request = mock('Net::HTTP')
  
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ERR: 002, Unknown username or password')
      
    host = URI::parse('https://api.clickatell.com')
    
    params = {
      :api_id => 'api1',
      :user => 'user1',
      :password => 'pass1',
      :from => 'someone',
      :mo => '1',
      :to => '5678',
      :text => 'text me'
    }
    uri = "/http/sendmsg?#{params.to_query}"
    
    Net::HTTP.expects(:new).with(host.host, host.port).returns(request)
    request.expects('use_ssl=').with(true)
    request.expects('verify_mode=').with(OpenSSL::SSL::VERIFY_NONE)
    request.expects(:get).with(uri).returns(response)
    
    account = Account.create(:name => 'account', :password => 'pass')
    chan = Channel.new(:account_id => account.id, :name => 'chan', :protocol => 'protocol', :kind => 'clickatell', :direction => Channel::Bidirectional)
    chan.configuration = {:api_id => 'api1', :user => 'user1', :password => 'pass1', :from => 'someone', :incoming_password => 'pass2'}
    assert_true chan.save!
    
    msg = AOMessage.create(:account_id => account.id, :from => 'sms://1234', :to => 'sms://5678', :body => 'text me', :state => 'queued')
    
    job = SendClickatellMessageJob.new(account.id, chan.id, msg.id)
    job.perform
    
    msg = AOMessage.first
    assert_equal 0, msg.tries
    assert_equal 'queued', msg.state
    
    chan.reload
    assert_false chan.enabled
  end
end
