require 'test_helper'

class DtacChannelHandlerTest < ActiveSupport::TestCase
  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'dtac', :protocol => 'sms')
    @chan.configuration = {:user => 'user', :password => 'password', :sno => 'sno' }
  end
  
  [:user, :password, :sno].each do |field|
    test "should validate configuration presence of #{field}" do
      assert_validates_configuration_presence_of @chan, field
    end
  end
  
  test "should save" do
    assert @chan.save
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendDtacMessageJob
  end
end
