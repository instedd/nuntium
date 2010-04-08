require 'test_helper'

class TwitterChannelHandlerTest < ActiveSupport::TestCase
  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'twitter', :protocol => 'sms')
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendTwitterMessageJob
  end
end
