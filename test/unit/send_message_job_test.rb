require 'test_helper'

class SendMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  test "should disable channel temporarily on permanent exception" do
    account = Account.make
    channel = Channel.make :account => account
    msg = AOMessage.make :account => account
  
    job = SendMessageJob.new account.id, channel.id, msg.id
    job.expects(:managed_perform).raises(PermanentException.new(Exception.new('ex')))
    
    job.perform
    
    channel.reload
    assert_false channel.enabled
  end
end
