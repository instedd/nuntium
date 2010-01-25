require 'test_helper'

class ApplicationTest < ActiveSupport::TestCase

  test "should not save if name is blank" do
    app = Application.new(:password => 'foo')
    assert !app.save
  end
  
  test "should not save if password is blank" do
    app = Application.new(:name => 'app')
    assert !app.save
  end
  
  test "should not save if password confirmation fails" do
    app = Application.new(:name => 'app', :password => 'foo', :password_confirmation => 'foo2')
    assert !app.save
  end
  
  test "should not save if name is taken" do
    Application.create!(:name => 'app', :password => 'foo')
    app = Application.new(:name => 'app', :password => 'foo2')
    assert !app.save
  end
  
  test "should save app" do
    app = Application.new(:name => 'app', :password => 'foo', :password_confirmation => 'foo')
    assert app.save
  end
  
  test "should find by name" do
    app1 = Application.create!(:name => 'app', :password => 'foo')
    app2 = Application.find_by_name 'app'
    assert_equal app1.id, app2.id
  end
  
  test "should authenticate" do
    app1 = Application.create!(:name => 'app', :password => 'foo')
    assert app1.authenticate('foo')
    assert !app1.authenticate('foo2')
  end
  
  test "should find by id if numerical" do
    app = Application.create!(:name => 'app', :password => 'foo')
    found = Application.find_by_id_or_name(app.id.to_s)
    assert_equal app, found
  end
  
  test "should find by name if string" do
    app = Application.create!(:name => 'app2', :password => 'foo')
    found = Application.find_by_id_or_name('app2')
    assert_equal app, found
  end
  
  test "ao routing change from" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.configuration[:ao_routing] = "msg.from = 'sms://1234'"
    app.save!
    
    chan1 = new_channel app, 'Uno'
    chan2 = new_channel app, 'Dos'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    assert_equal 'sms://1234', msg.from
    
    msg = AOMessage.all[0]
    assert_equal 'sms://1234', msg.from
  end
  
  test "ao routing change from twice" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.configuration[:ao_routing] = "msg.from = 'sms://1234'"
    app.save!
    
    chan1 = new_channel app, 'Uno'
    chan2 = new_channel app, 'Dos'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    assert_equal 2, AOMessage.all.length
    
    assert_equal 'sms://1234', msg.from
  end
  
  test "ao routing select channel by name" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.configuration[:ao_routing] = "msg.route_to_channel 'Dos'"
    app.save!
    
    chan1 = new_channel app, 'Uno'
    chan2 = new_channel app, 'Dos'
    chan2.metric = chan1.metric + 100
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan2.id, qsts[0].channel_id
  end
  
  test "ao routing select channel by array" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.configuration[:ao_routing] = "msg.route_to_any_channel 'Dos', 'Tres'"
    app.save!
    
    chan1 = new_channel app, 'Uno'
    chan2 = new_channel app, 'Dos'
    chan2.metric = chan1.metric + 100
    chan2.save!
    chan3 = new_channel app, 'Tres'
    chan3.metric = chan1.metric + 90
    chan3.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan3.id, qsts[0].channel_id
  end
  
  test "ao routing change application" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.configuration[:ao_routing] = "msg.route_to_application 'app2'"
    app1.save!
    
    app2 = Application.create!(:name => 'app2', :password => 'foo')
    
    chan1 = new_channel app1, 'Uno'
    chan2 = new_channel app1, 'Dos'
    chan3 = new_channel app2, 'Tres'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app1.route(msg, 'test')
    
    assert_equal 1, AOMessage.all.length
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan3.id, qsts[0].channel_id
  end
  
  test "ao routing copy in two channels" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.configuration[:ao_routing] = "msg.copy{|x| x.from = 'UNO'; x.route_to_channel 'Uno'}; msg.copy{|x| x.from = 'DOS'; x.route_to_channel 'Dos'};"
    app1.save!
    
    app2 = Application.create!(:name => 'app2', :password => 'foo')
    
    chan1 = new_channel app1, 'Uno'
    chan2 = new_channel app1, 'Dos'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app1.route(msg, 'test')
    
    msgs = AOMessage.all
    assert_equal 2, msgs.length
    assert_equal 'UNO', msgs[0].from
    assert_equal 'DOS', msgs[1].from
    
    qsts = QSTOutgoingMessage.all
    assert_equal 2, qsts.length
    assert_equal chan1.id, qsts[0].channel_id
    assert_equal chan2.id, qsts[1].channel_id
  end
  
  test "ao routing route to any channel test passes" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.configuration[:ao_routing] = "msg.from = 'bar'"
    app.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'bar'})" 
    assert_true app.save
  end
  
  test "ao routing route to any channel test fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.configuration[:ao_routing] = "msg.from = 'bar'"
    app.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'baZ'})" 
    assert_false app.save
  end
  
  test "ao routing route to any channel explicit test passes" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.route_to_any_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, 'Uno')" 
    assert_true app.save
  end
  
  test "ao routing route to any channel explicit test fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.route_to_any_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, 'Dos')" 
    assert_false app.save
  end
  
  test "ao routing route to any channel explicit test fails many" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.route_to_any_channel 'Uno', 'Dos'"
    app.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, 'Dos')" 
    assert_false app.save
  end
  
  test "ao routing route to any channel explicit and change from test passes" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_any_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'bar'}, 'Uno')" 
    assert_true app.save
  end
  
  test "ao routing route to any channel explicit and change from test fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_any_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_any_channel({:from => 'foo'}, {:from => 'foo'}, 'Uno')" 
    assert_false app.save
  end
  
  test "ao routing route to channel test passes" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.route_to_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, 'Uno')" 
    assert_true app.save
  end
  
  test "ao routing route to channel test fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.route_to_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, 'Dos')" 
    assert_false app.save
  end
  
  test "ao routing route to channel and change from test passes" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, {:from => 'bar'}, 'Uno')" 
    assert_true app.save
  end
  
  test "ao routing route to channel and change from test fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    chan = new_channel app, 'Uno'
    
    app.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_channel 'Uno'"
    app.configuration[:ao_routing_test] = "assert.routed_to_channel({:from => 'foo'}, {:from => 'foo'}, 'Uno')" 
    assert_false app.save
  end
  
   test "ao routing route to application test passes" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    app.configuration[:ao_routing] = "msg.route_to_application 'app'"
    app.configuration[:ao_routing_test] = "assert.routed_to_application({:from => 'foo'}, 'app')" 
    assert_true app.save
  end
  
  test "ao routing route to application test fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    app.configuration[:ao_routing] = "msg.route_to_application 'app'"
    app.configuration[:ao_routing_test] = "assert.routed_to_application({:from => 'foo'}, 'app2')" 
    assert_false app.save
  end
  
  test "ao routing route to application and change from test passes" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    app.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_application 'app'"
    app.configuration[:ao_routing_test] = "assert.routed_to_application({:from => 'foo'}, {:from => 'bar'}, 'app')" 
    assert_true app.save
  end
  
  test "ao routing route to application and change from test fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    app.configuration[:ao_routing] = "msg.from = 'bar'; msg.route_to_application 'app'"
    app.configuration[:ao_routing_test] = "assert.routed_to_application({:from => 'foo'}, {:from => 'foo'}, 'app')" 
    assert_false app.save
  end
  
  test "ao routing route same message twice fails" do
    app = Application.new(:name => 'app', :password => 'foo')
    assert_true app.save
    
    app.configuration[:ao_routing] = "msg.route_to_channel 'one'; msg.route_to_application 'app'"
    app.configuration[:ao_routing_test] = "assert.routed_to_application({}, {}, 'app')" 
    assert_false app.save
  end
  
  test "at routing" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.configuration[:at_routing] = "msg.from = 'foo'"
    app1.save!
    
    chan = new_channel app1, 'Uno'
    
    msg = ATMessage.new(:application_id => app1.id, :from => 'bar')
    app1.accept msg, chan    
    
    assert_equal 'foo', msg.from
    assert_equal 'foo', ATMessage.all[0].from
  end
  
  test "at routing change application" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.configuration[:at_routing] = "msg.application = Application.find_by_name 'app2'"
    app1.save!
    
    app2 = Application.create!(:name => 'app2', :password => 'foo')
    
    chan = new_channel app1, 'Uno'
    
    msg = ATMessage.new(:application_id => app1.id, :from => 'bar')
    app1.accept msg, chan    
    
    assert_equal app2.id, ATMessage.all[0].application_id
  end
  
  test "at routing test passes" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.configuration[:at_routing] = "msg.from = 'foo'"
    app1.configuration[:at_routing_test] = "assert.transform({:from => 'bar'}, {:from => 'foo'})"
    assert_true app1.save
  end
  
  test "at routing inspect channel" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.save!
    
    chan1 = new_channel app1, 'Uno'
    chan2 = new_channel app1, 'Dos'
    
    app1.configuration[:at_routing] = "if !msg.channel.nil? && msg.channel.name == 'Uno'; msg.from = 'bar'; end;"
    app1.save!
    
    msg = ATMessage.new(:from => 'foo')
    app1.accept(msg, chan1)
    assert_equal 'bar', msg.from
  end
  
  test "at routing test fails" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.configuration[:at_routing] = "msg.from = 'foo'"
    app1.configuration[:at_routing_test] = "assert.transform({:from => 'bar'}, {:from => 'bar'})"
    assert_false app1.save
  end
  
  def new_channel(app, name)
    chan = Channel.new(:application_id => app.id, :name => name, :kind => 'qst_server', :protocol => 'sms', :direction => Channel::Both);
    chan.configuration = {:url => 'a', :user => 'b', :password => 'c'};
    chan.save!
    chan
  end
  
end
