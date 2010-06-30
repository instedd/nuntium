require 'test_helper'

class SendDtacMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :dtac
  end

  should "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200', 
      :message => 'OK', 
      :content_type => 'text/plain', 
      :read_body => 'Status=0')
      
    msg = AOMessage.make :account => Account.make, :channel => @chan
    
    expect_http_post msg, response    
    assert (deliver msg)
    
    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
  
  def expect_http_post(msg, response)    
    Net::HTTP.expects(:post_form).returns(response)
  end
  
  def deliver(msg)
    job = SendDtacMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end
  
  def check_message_was_delivered(channel_relative_id)
    msg = AOMessage.first
    assert_equal channel_relative_id, msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
end
