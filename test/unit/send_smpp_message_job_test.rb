require 'test_helper'

class SendSmppMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :smpp
  end
  
  test "dont sent message if its not queued" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :state => 'delivered'
    
    job = SendSmppMessageJob.new msg.account_id, @chan.id, msg.id
    job.perform nil
    
    assert_equal 'delivered', msg.state
  end
  
  test "dont sent message if in another channel" do
    msg = AOMessage.make :account => @chan.account, :state => 'delivered'
    
    job = SendSmppMessageJob.new msg.account_id, @chan.id, msg.id
    job.perform nil
    
    assert_equal 'delivered', msg.state
  end
  
end
