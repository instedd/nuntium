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
    assert_equal 'something', AOMessage.first.subject
  end
  
  test "alert fails semantic error" do
    app = Application.create!(:name => 'app', :password => 'pass')
    app.configuration = {:alert => "trigger.alert 'k1'"}
    
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for app
    
    assert_equal 1, Alert.count
    assert_true AOMessage.first.subject.include?('You have an error in your alert code:')
  end
  
   test "does nothing if no alert config" do
    app = Application.create!(:name => 'app', :password => 'pass')
    
    chan = new_channel(app, 'one')
    cfg = AlertConfiguration.create!(:application_id => app.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for app
    
    assert_equal 0, Alert.count
  end
  
end
