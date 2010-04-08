require 'test_helper'

class ChannelTest < ActiveSupport::TestCase
  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new :name =>'channel', :application_id => @app.id, :kind => 'qst_server', :protocol => 'sms'
    @chan.configuration = {:password => 'foo', :password_confirmation => 'foo'}
  end
  
  [:name, :kind, :protocol, :application_id].each do |field|
    test "should validate presence of #{field}" do
      @chan.send("#{field}=", nil)
      assert !@chan.save
    end
  end
  
  test "should not save if name is taken" do
    chan2 = Channel.new :name =>'channel', :application_id => @app.id, :kind => 'qst_server', :protocol => 'sms'
    chan2.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    assert chan2.save
    assert !@chan.save
  end
  
  test "should save if name is taken in another app" do
    app2 = Application.create(:name => 'app2', :password => 'foo')
    chan2 = Channel.new :name =>'channel', :application_id => app2.id, :kind => 'qst_server', :protocol => 'sms'
    chan2.configuration = {:password => 'foo', :password_confirmation => 'foo'}
    assert chan2.save
    assert @chan.save
  end
  
  test "should be enabled by default" do
    @chan.save
    assert @chan.enabled
  end
end
