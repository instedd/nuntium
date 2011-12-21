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

  test "send message" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'

    job = SendSmppMessageJob.new msg.account_id, @chan.id, msg.id
    delegate = mock('delegate')
    delegate.expects(:send_message).with(msg.id, msg.from.without_protocol, msg.to.without_protocol, msg.subject_and_body, {})
    assert job.perform(delegate)
  end

  test "send message with smpp custom options" do
    msg = AoMessage.make :account => @chan.account, :channel => @chan, :state => 'queued',
      :custom_attributes => {'smpp_1234' => 'foo', 'smpp_0x1234' => 'bar', 'something' => 'baz'}

    job = SendSmppMessageJob.new msg.account_id, @chan.id, msg.id
    delegate = mock('delegate')
    delegate.expects(:send_message).with(msg.id, msg.from.without_protocol, msg.to.without_protocol, msg.subject_and_body,
      {1234 => 'foo', 0x1234 => 'bar'})
    assert job.perform(delegate)
  end

end
