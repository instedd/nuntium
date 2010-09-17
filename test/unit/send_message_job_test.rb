require 'test_helper'

class SendMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "should disable channel temporarily on permanent exception" do
    account = Account.make
    channel = Channel.make :account => account
    msg = AOMessage.make :account => account, :channel => channel, :state => 'queued'
  
    job = SendMessageJob.new account.id, channel.id, msg.id
    job.expects(:managed_perform).raises(PermanentException.new(Exception.new('ex')))
    
    job.perform
    
    channel.reload
    assert_false channel.enabled
  end
  
  test "should increment tries on temporary exception" do
    account = Account.make
    channel = Channel.make :account => account
    msg = AOMessage.make :account => account, :channel => channel, :state => 'queued'
  
    job = SendMessageJob.new account.id, channel.id, msg.id
    job.expects(:managed_perform).raises(Exception.new('ex'))
    
    begin
      job.perform
      fail 'Should have re-thrown the exception'
    rescue Exception => ex
    end
    
    msg.reload
    assert_equal 1, msg.tries
  end
  
  test "should not execute if the message is queued on a different channel" do
    account = Account.make
    channel1 = Channel.make :account => account
    channel2 = Channel.make :account => account
    msg = AOMessage.make :account => account, :channel => channel2
    
    job = SendMessageJob.new account.id, channel1.id, msg.id
    job.expects(:managed_perform).never
    
    assert_true job.perform
  end
  
  test "should not execute if the message is not in 'queued' state" do
    account = Account.make
    channel = Channel.make :account => account
    msg = AOMessage.make :account => account, :channel => channel, :state => 'canceled'
    
    job = SendMessageJob.new account.id, channel.id, msg.id
    job.expects(:managed_perform).never
    
    assert_true job.perform
  end
end
