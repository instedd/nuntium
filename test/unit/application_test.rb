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
    app.ao_routing = "msg.from = 'sms://1234' \r\n nil"
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
    app.ao_routing = "msg.from = 'sms://1234' \r\n nil"
    app.save!
    
    chan1 = new_channel app, 'Uno'
    chan2 = new_channel app, 'Dos'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    assert_equal 'sms://1234', msg.from
  end
  
  test "ao routing select channel by name" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.ao_routing = "'Dos'"
    app.save!
    
    chan1 = new_channel app, 'Uno'
    chan2 = new_channel app, 'Dos'
    chan2.metric = chan1.metric + 100
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan2.id, qsts[0].channel_id
  end
  
  test "ao routing select channel by array" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.ao_routing = "['Dos', 'Tres']"
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
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan3.id, qsts[0].channel_id
  end
  
  test "ao routing select channel explicitly" do
    app = Application.new(:name => 'app', :password => 'foo')
    app.ao_routing = "channels.select{|x| x.name == 'Dos'}"
    app.save!
    
    chan1 = new_channel app, 'Uno'
    chan2 = new_channel app, 'Dos'
    chan2.metric = chan1.metric + 100
    chan2.save!
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app.route(msg, 'test')
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan2.id, qsts[0].channel_id
  end
  
  test "ao routing change application" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.ao_routing = "msg.application = Application.find_by_name 'app2'"
    app1.save!
    
    app2 = Application.create!(:name => 'app2', :password => 'foo')
    
    chan1 = new_channel app1, 'Uno'
    chan2 = new_channel app1, 'Dos'
    chan3 = new_channel app2, 'Tres'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app1.route(msg, 'test')
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan3.id, qsts[0].channel_id
  end
  
  test "ao routing change application id" do
    app1 = Application.new(:name => 'app1', :password => 'foo')
    app1.ao_routing = "msg.application.id = Application.find_by_name('app2').id"
    app1.save!
    
    app2 = Application.create!(:name => 'app2', :password => 'foo')
    
    chan1 = new_channel app1, 'Uno'
    chan2 = new_channel app1, 'Dos'
    chan3 = new_channel app2, 'Tres'
    
    msg = AOMessage.new(:from => 'sms://4321', :to => 'sms://5678', :subject => 'foo', :body => 'bar')
    app1.route(msg, 'test')
    
    qsts = QSTOutgoingMessage.all
    assert_equal 1, qsts.length
    assert_equal chan3.id, qsts[0].channel_id
    
    logs = ApplicationLog.all
    assert_equal 4, logs.length
    assert_equal "Message received from application 'app1'", logs[2].message
  end
  
  def new_channel(app, name)
    chan = Channel.new(:application_id => app.id, :name => name, :kind => 'qst_server', :protocol => 'sms', :direction => Channel::Both);
    chan.configuration = {:url => 'a', :user => 'b', :password => 'c'};
    chan.save!
    chan
  end
  
end
