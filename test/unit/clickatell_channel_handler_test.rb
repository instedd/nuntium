require 'test_helper'

class ClickatellChannelHandlerTest < ActiveSupport::TestCase
  test "should not save if user is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms', :configuration => {:password => 'pass', :api_id => 'api_id' })
    assert !chan.save
  end
  
  test "should not save if password is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms', :configuration => {:user => 'user', :api_id => 'api_id' })
    assert !chan.save
  end
  
  test "should not save if api id is blank" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms', :configuration => {:user => 'user', :password => 'password' })
    assert !chan.save
  end
  
  test "should save" do
    app = Application.create(:name => 'app', :password => 'foo')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :kind => 'clickatell', :protocol => 'sms', :configuration => {:user => 'user', :password => 'password', :api_id => 'api_id' })
    assert chan.save
  end
end
