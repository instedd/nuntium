require 'test_helper'

class QstServerChannelHandlerTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :qst_server, :configuration => {:password => 'foo', :password_confirmation => 'foo'}
  end
  
  test "should not save if password is blank" do
    @chan.configuration.delete :password
    assert_false @chan.save
  end
  
  test "should not save if password confirmation is wrong" do
    @chan.configuration[:password_confirmation] = 'foo2'
    assert_false @chan.save
  end
  
  test "should authenticate" do
    assert @chan.handler.authenticate('foo')
    assert_false @chan.handler.authenticate('foo2')
  end
  
  test "should update" do
    assert @chan.save
  end
end
