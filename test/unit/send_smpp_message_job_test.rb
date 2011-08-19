require 'test_helper'

class SendSmppMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = SmppChannel.make
  end

  test "dont sent message if its not queued" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan, :state => 'delivered'

    job = SendSmppMessageJob.new msg.account_id, @chan.id, msg.id
    assert_false (job.perform nil)

    assert_equal 'delivered', msg.state
  end

  test "dont sent message if in another channel" do
    msg = AoMessage.make :account => @chan.account, :state => 'delivered'

    job = SendSmppMessageJob.new msg.account_id, @chan.id, msg.id
    assert_false (job.perform nil)

    assert_equal 'delivered', msg.state
  end

end
