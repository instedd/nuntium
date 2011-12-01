require 'test_helper'

class ChannelOptInTest < ActiveSupport::TestCase
  def setup
    @chan = QstServerChannel.make_unsaved
    @chan.opt_in_enabled = true
    @chan.opt_in_keyword = 'in'
    @chan.opt_in_message = 'in message'
    @chan.opt_out_keyword = 'out'
    @chan.opt_out_message = 'out message'
    @chan.opt_help_keyword = 'help'
    @chan.opt_help_message = 'help message'
    @chan.save!

    @app = @chan.account.applications.make
  end

  test "replies help message for opt-in help keyword" do
    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'help'
    @chan.route_at msg

    msg.reload

    assert_equal 'replied', msg.state
    assert_nil msg.application_id

    msgs = AoMessage.all
    assert_equal 1, msgs.length
    assert_equal @chan.account_id, msgs[0].account_id
    assert_equal @chan.id, msgs[0].channel_id
    assert_equal msg.to, msgs[0].from
    assert_equal msg.from, msgs[0].to
    assert_equal @chan.opt_help_message, msgs[0].body
  end

  test "doesn't reply help message for opt-in help keyword if opt in is disabled" do
    @chan.opt_in_enabled = false

    msg = AtMessage.new :from => 'sms://1', :to => 'sms://2', :body => 'help'
    @chan.route_at msg

    msg.reload

    assert_equal 'queued', msg.state

    assert_equal 0, AoMessage.count
  end
end
