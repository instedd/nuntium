require 'test_helper'

class QstServerChannelTest < ActiveSupport::TestCase
  def setup
    @chan = QstServerChannel.make :configuration => {:password => 'foo', :password_confirmation => 'foo'}
  end

  test "should not save if password is blank" do
    @chan.configuration.delete :password
    assert_false @chan.save
  end

  test "should not save if password confirmation is wrong" do
    @chan.password_confirmation = 'foo2'
    assert_false @chan.save
  end

  test "should authenticate" do
    assert @chan.authenticate('foo')
    assert_false @chan.authenticate('foo2')
  end

  test "should authenticate if save with blank password" do
    @chan.configuration = {:password => '', :password_confirmation => ''}
    @chan.save!

    @chan.reload

    assert @chan.authenticate('foo')
  end

  test "should authenticate after password changed" do
    @chan.configuration = {:password => 'foo2', :password_confirmation => 'foo2'}
    @chan.save!

    @chan.reload

    assert @chan.authenticate('foo2')
  end

  test "should update" do
    assert @chan.save
  end
end
