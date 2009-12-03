require 'test_helper'

class ChannelTest < ActiveSupport::TestCase
  test "should not save if name is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :kind => 'qst', :protocol => 'sms', :configuration => {:password => 'pass'})
    assert !chan.save
  end
  
  test "should not save if kind is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :protocol => 'sms', :configuration => {:password => 'pass'})
    assert !chan.save
  end
  
  test "should not save if protocol is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'qst', :configuration => {:password => 'pass'})
    assert !chan.save
  end
  
  test "should not save if name is taken" do
    app = Application.create(:name => 'app', :password => 'foo')
    ch1 = Channel.new :name =>'channel', :application_id => app.id, :kind => 'qst', :protocol => 'sms'
    ch1.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    ch2 = Channel.new :name =>'channel', :application_id => app.id, :kind => 'qst', :protocol => 'sms'
    ch2.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    assert  ch1.save
    assert !ch2.save
  end
  
  test "should save if name is taken in another app" do
    app1 = Application.create(:name => 'app', :password => 'foo')
    app2 = Application.create(:name => 'app2', :password => 'foo')
    ch1 = Channel.new :name =>'channel', :application_id => app1.id, :kind => 'qst', :protocol => 'sms'
    ch1.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    ch2 = Channel.new :name =>'channel', :application_id => app2.id, :kind => 'qst', :protocol => 'sms'
    ch2.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    assert ch1.save
    assert ch2.save
  end
  
  test "should not save if application_id is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:name => 'chan', :kind => 'qst', :protocol => 'sms', :configuration => {:password => 'foo', :password_confirmation => 'foo'})
    assert !chan.save
  end
end
