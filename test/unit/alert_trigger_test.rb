require 'test_helper'

class AlertTriggerTest < ActiveSupport::TestCase
  test "alert" do
    app = Application.create!(:name => 'app', :password => 'pass')
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    trigger = AlertTrigger.new(app)
    trigger.alert('k1', 'something')
    
    msgs = AOMessage.all
    assert_equal 1, msgs.length
    assert_equal app.id, msgs[0].application_id
    assert_equal 'f', msgs[0].from
    assert_equal 't', msgs[0].to
    assert_equal 'something', msgs[0].subject
    assert_equal 'pending', msgs[0].state
    
    alerts = Alert.all
    assert_equal 1, alerts.length
    assert_equal app.id, alerts[0].application_id
    assert_equal chan.id, alerts[0].channel_id
    assert_equal msgs[0].id, alerts[0].ao_message_id
    
    # Second trigger in less than an hour doesn't modify anything
    trigger.alert('k1', 'something else')
    
    alerts = Alert.all
    assert_equal 1, AOMessage.count
    assert_equal 1, alerts.length
    
    # Expire alert
    alerts[0].sent_at = Time.now.utc - (1.hours.to_i + 1)
    alerts[0].save!
    
    # This time alert should be updated and new AOMessage created
    trigger.alert('k1', 'and another thing')
    msgs = AOMessage.all
    assert_equal 2, msgs.length
    assert_equal 'and another thing', msgs[1].subject
    alerts = Alert.all
    assert_equal 1, alerts.length
    assert_equal msgs[1].id, alerts[0].ao_message_id
  end
  
end
