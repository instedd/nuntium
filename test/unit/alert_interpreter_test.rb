require 'test_helper'

class AlertInterpreterTest < ActiveSupport::TestCase
  test "alert" do
    account = Account.create!(:name => 'account', :password => 'pass')
    account.configuration = {:alert => "trigger.alert 'k1', 'something'"}
    
    chan = new_channel(account, 'one')
    cfg = AlertConfiguration.create!(:account_id => account.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for account
    
    assert_equal 1, Alert.count
    msg = AOMessage.first
    assert_equal 'Nuntium alert for account', msg.subject
    assert_equal 'something', msg.body
  end
  
  test "alert fails semantic error" do
    account = Account.create!(:name => 'account', :password => 'pass')
    account.configuration = {:alert => "trigger.alert 'k1'"}
    
    chan = new_channel(account, 'one')
    cfg = AlertConfiguration.create!(:account_id => account.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for account
    
    assert_equal 1, Alert.count
    assert_true AOMessage.first.body.include?('You have an error in your alert code:')
  end
  
   test "does nothing if no alert config" do
    account = Account.create!(:name => 'account', :password => 'pass')
    
    chan = new_channel(account, 'one')
    cfg = AlertConfiguration.create!(:account_id => account.id, :channel_id => chan.id, :from => 'f', :to => 't')
    
    interpreter = AlertInterpreter.new
    interpreter.interpret_for account
    
    assert_equal 0, Alert.count
  end
  
  test "alert bug" do
    interpreter = AlertInterpreter.new
  
    account = Account.create!(:name => 'account', :password => 'pass')
    account.configuration = {:alert => "trigger.alert 'k1', 'something'"}
    
    chan1 = new_channel(account, 'one')
    chan2 = new_channel(account, 'two')
    cfg1 = AlertConfiguration.create!(:account_id => account.id, :channel_id => chan1.id, :from => 'f', :to => 'c1a, c1b')
    cfg2 = AlertConfiguration.create!(:account_id => account.id, :channel_id => chan2.id, :from => 'f', :to => 'c2')
    
    interpreter.interpret_for account
    
    assert_equal [chan1.id, chan1.id, chan2.id], Alert.all.map(&:channel_id)
    assert_equal [chan1.id, chan1.id, chan2.id], AOMessage.all.map(&:channel_id)
    
    Alert.update_all(['sent_at = ?', Time.now - 2.hours])
    
    interpreter.interpret_for account
    
    assert_equal [chan1.id, chan1.id, chan2.id], Alert.all.map(&:channel_id)
    assert_equal [chan1.id, chan1.id, chan2.id], AOMessage.all[3 .. -1].map(&:channel_id)
  end
  
end
