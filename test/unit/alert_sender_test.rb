require 'test_helper'

class AlertSenderTest < ActiveSupport::TestCase
  test "alert" do
    account = Account.create!(:name => 'account', :password => 'pass')
    chan = new_channel(account, 'one')
    cfg = AlertConfiguration.create!(:account_id => account.id, :channel_id => chan.id, :from => 'f', :to => 't')
    msg = AOMessage.create!(:account_id => account.id, :from => 'f', :to => 't', :subject => 's', :state => 'pending')
    alert = Alert.create!(:account_id => account.id, :channel_id => chan.id, :ao_message_id => msg.id)
    
    sender = AlertSender.new
    sender.perform
    
    alerts = Alert.all
    assert_equal 1, alerts.length
    assert_not_nil alerts[0].sent_at
    assert_false alerts[0].failed
    
    assert_equal 'pending', AOMessage.first.state
  end
  
  test "alert remove when tries exceeded" do
    account = Account.create!(:name => 'account', :password => 'pass')
    chan = new_channel(account, 'one')
    cfg = AlertConfiguration.create!(:account_id => account.id, :channel_id => chan.id, :from => 'f', :to => 't')
    msg = AOMessage.create!(:account_id => account.id, :from => 'f', :to => 't', :subject => 's', :state => 'pending', :tries => 3)
    alert = Alert.create!(:account_id => account.id, :channel_id => chan.id, :ao_message_id => msg.id)
    
    sender = AlertSender.new
    sender.perform
    
    alerts = Alert.all
    assert_equal 1, alerts.length
    assert_not_nil alerts[0].sent_at
    assert_true alerts[0].failed
    
    assert_equal 'failed', AOMessage.first.state
  end
  
end
