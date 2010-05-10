require 'test_helper'

class QstServerChannelHandlerTest < ActiveSupport::TestCase
  def setup
    @account = Account.create(:name => 'account', :password => 'foo')
    @chan = Channel.new(:account_id => @account.id, :name => 'chan', :kind => 'qst_server', :protocol => 'sms', :direction => Channel::Bidirectional)
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
