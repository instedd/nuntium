require 'test_helper'

class AlertSenderTest < ActiveSupport::TestCase
  test "alert" do
    app = Application.create!(:name => 'app', :password => 'pass')
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    msg = AOMessage.create!(:application_id => app.id, :from => 'f', :to => 't', :subject => 's', :state => 'pending')
    alert = Alert.create!(:application_id => app.id, :channel_id => chan.id, :ao_message_id => msg.id)
    
    sender = AlertSender.new
    sender.perform
    
    alerts = Alert.all
    assert_equal 1, alerts.length
    assert_not_nil alerts[0].sent_at
    
    assert_equal 'pending', AOMessage.first.state
  end
  
  test "alert remove when tries exceeded" do
    app = Application.create!(:name => 'app', :password => 'pass')
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    msg = AOMessage.create!(:application_id => app.id, :from => 'f', :to => 't', :subject => 's', :state => 'pending', :tries => 3)
    alert = Alert.create!(:application_id => app.id, :channel_id => chan.id, :ao_message_id => msg.id)
    
    sender = AlertSender.new
    sender.perform
    
    alerts = Alert.all
    assert_equal 0, alerts.length
    
    assert_equal 'failed', AOMessage.first.state
  end
  
end
