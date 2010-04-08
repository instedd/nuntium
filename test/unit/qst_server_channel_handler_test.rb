require 'test_helper'

class QstServerChannelHandlerTest < ActiveSupport::TestCase
  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'qst_server', :protocol => 'sms')
    @chan.configuration = {:password => 'foo', :password_confirmation => 'foo'}
  end
  
  test "should not save if password is blank" do
    @chan.configuration.delete :password
    assert !@chan.save
  end
  
  test "should not save if password confirmation is wrong" do
    @chan.configuration[:password_confirmation] = 'foo2'
    assert !@chan.save
  end
  
  test "should save" do
    assert @chan.save
  end
  
  test "should authenticate" do
    @chan.save
    
    assert @chan.handler.authenticate('foo')
    assert !@chan.handler.authenticate('foo2')
  end
end
