require 'test_helper'

class AlertInterpreterTest < ActiveSupport::TestCase
  test "alert" do
    app = Application.create!(:name => 'app', :password => 'pass')
    app.configuration = {:alert => "trigger.alert 'k1', 'something'"}
    
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for app
    
    assert_equal 1, Alert.count
    msg = AOMessage.first
    assert_equal 'Nuntium alert for app', msg.subject
    assert_equal 'something', msg.body
  end
  
  test "alert fails semantic error" do
    app = Application.create!(:name => 'app', :password => 'pass')
    app.configuration = {:alert => "trigger.alert 'k1'"}
    
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for app
    
    assert_equal 1, Alert.count
    assert_true AOMessage.first.body.include?('You have an error in your alert code:')
  end
  
   test "does nothing if no alert config" do
    app = Application.create!(:name => 'app', :password => 'pass')
    
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for app
    
    assert_equal 0, Alert.count
  end
  
  test "alert bug" do
    interpreter = AlertInterpreter.new
  
    app = Application.create!(:name => 'app', :password => 'pass')
    app.configuration = {:alert => "trigger.alert 'k1', 'something'"}
    
    chan1 = new_channel(app, 'one')
    chan2 = new_channel(app, 'two')
    cfg1 = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan1.id, :from => 'f', :to => 'c1a, c1b')
    cfg2 = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan2.id, :from => 'f', :to => 'c2')
    
    interpreter.interpret_for app
    
    assert_equal [chan1.id, chan1.id, chan2.id], Alert.all.map(&:channel_id)
    assert_equal [chan1.id, chan1.id, chan2.id], AOMessage.all.map(&:channel_id)
    
    Alert.update_all(['sent_at = ?', Time.now - 2.hours])
    
    interpreter.interpret_for app
    
    assert_equal [chan1.id, chan1.id, chan2.id], Alert.all.map(&:channel_id)
    assert_equal [chan1.id, chan1.id, chan2.id], AOMessage.all[3 .. -1].map(&:channel_id)
  end
  
end
