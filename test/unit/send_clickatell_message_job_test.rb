require 'test_helper'

class SendClickatellMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :clickatell
  end

  should "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ID: msgid')
      
    msg = AOMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'
    
    expect_rest msg, response    
    assert (deliver msg)
    
    msg = AOMessage.first
    assert_equal 'msgid', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
  
  should "perform error" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ERR: 105, Invalid destination address')
      
    msg = AOMessage.make :account => Account.make, :channel => @chan
    
    expect_rest msg, response 
    assert (deliver msg)
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'failed', msg.state
    
    logs = AccountLog.all
    assert_equal 1, logs.length
    assert_true logs[0].message.include?('105, Invalid destination address')
  end
  
  should "perform fatal error" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :body => 'ERR: 002, Unknown username or password')
      
    msg = AOMessage.make :account => Account.make, :channel => @chan
    
    expect_rest msg, response 
    assert_false (deliver msg)
    
    msg = AOMessage.first
    assert_equal 0, msg.tries
    assert_equal 'queued', msg.state
    
    @chan.reload
    assert_false @chan.enabled
  end
  
  def expect_rest(msg, response)
    params = {
      :api_id => @chan.configuration[:api_id],
      :user => @chan.configuration[:user],
      :password => @chan.configuration[:password],
      :from => @chan.configuration[:from],
      :mo => '1',
      :to => msg.to.without_protocol,
      :text => msg.subject_and_body,
      :climsgid => msg.guid.gsub('-', ''),
    }
    
    Clickatell.expects(:send_message).with(params).returns(response)
  end
  
  def deliver(msg)
    job = SendClickatellMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end
  
  def check_message_was_delivered(channel_relative_id)
    msg = AOMessage.first
    assert_equal channel_relative_id, msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
end
