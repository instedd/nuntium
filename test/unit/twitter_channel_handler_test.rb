require 'test_helper'

class TwitterChannelHandlerTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @app = Application.create(:name => 'app', :password => 'foo')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :kind => 'twitter', :protocol => 'sms')
  end
  
  test "should enqueue" do
    assert_handler_should_enqueue_ao_job @chan, SendTwitterMessageJob
  end
  
  test "on enable binds queue" do
    Queues.expects(:bind_ao).with(@chan)
    @chan.save!
  end
  
  test "on enable publish notification" do
    Queues.expects(:publish_notification).with do |job|
      job.kind_of?(ChannelEnabledJob) and job.channel_id == @chan.id
    end
      
    @chan.save!
  end
end
