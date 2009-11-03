require 'test_helper'

class SmtpChannelHandlerTest < ActiveSupport::TestCase
  test "should not save if host is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'smtp', :protocol => 'sms', :configuration => {:port => 430, :user => 'user', :password => 'password' })
    assert !chan.save
  end
  
  test "should not save if port is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'smtp', :protocol => 'sms', :configuration => {:host => 'host', :user => 'user', :password => 'password' })
    assert !chan.save
  end
  
  test "should not save if user is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'smtp', :protocol => 'sms', :configuration => {:host => 'host', :password => 'password' })
    assert !chan.save
  end
  
  test "should not save if password is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'smtp', :protocol => 'sms', :configuration => {:host => 'host', :port => 430, :user => 'user' })
    assert !chan.save
  end
  
  test "should save" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'smtp', :protocol => 'sms', :configuration => {:host => 'host', :port => 430, :user => 'user', :password => 'password' })
    assert chan.save
  end
end
