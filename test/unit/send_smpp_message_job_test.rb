require 'test_helper'
require 'mocha'
require 'drb'

class SendSmppMessageJobTest < ActiveSupport::TestCase
  include Mocha::API

  setup :initialize_objects

  def initialize_objects
    @time = Time.now
    
    @app = Application.create!(:name => 'app', :password => 'pass')
    @chan = Channel.new(:application_id => @app.id, :name => 'chan', :protocol => 'smpp', :kind => 'smpp')
    @chan.configuration = {:host => 'the_host', :port => 3200, :source_ton => 0, :source_npi => 1, :destination_ton => 0, :destination_npi => 1, :user => 'the_user', :password => 'the_password', :use_latin1 => '0', :encoding => 'utf-8', :system_type => 'smpp', :mt_encodings => ['ascii'], :default_mo_encoding => 'ascii', :mt_csms_method => 'udh'}
    @chan.save!
    
    @msg = AOMessage.create!(:application_id => @app.id, :from => 'smpp://301', :to => 'smpp://856123456', :subject => 'some subject', :body => 'some body', :timestamp => @time, :guid => 'some guid', :state => 'pending')
  
    @job = SendSmppMessageJob.new(@app.id, @chan.id, @msg.id)  
  end

  should "throw :error_finding_drb_service if drb service is not found" do
    assert_equal(@job.perform, :error_finding_drb_service)
    
    aom = AOMessage.first
    assert_equal 'pending', aom.state
  end

  should "raise exception if drb service is not running" do
    drb = DRbProcess.create(:application_id => @app.id, :channel_id => @chan.id, :uri => 'druby://localhost:2250')    
    
    assert_raise(DRb::DRbConnError) { @job.perform }
    
    aom = AOMessage.first
    assert_equal 'pending', aom.state
  end

  should "terminate successfully if drb service is up and running" do
    uri = 'druby://localhost:2250';
    drb = DRbProcess.create(:application_id => @app.id, :channel_id => @chan.id, :uri => uri)
    
    class Stub
      def send_message(a, b, c, d)
        return nil
      end
    end

    DRb.start_service uri, Stub.new

    @job.perform
    
    aom = AOMessage.first
    assert_equal 'delivered', aom.state
  end
  
end
