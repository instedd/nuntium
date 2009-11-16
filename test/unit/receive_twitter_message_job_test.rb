require 'test_helper'

class ReceiveTwitterMessageJobTest < ActiveSupport::TestCase

  test "enqueue jobs" do
    app = Application.create(:name => 'app', :password => 'pass')
    chan1 = Channel.new(:application_id => app.id, :name => 'chan', :protocol => 'protocol', :kind => 'twitter')
    chan1.save
      
    chan2 = Channel.new(:application_id => app.id, :name => 'chan2', :protocol => 'protocol', :kind => 'twitter')
    chan2.save
    
    chan3 = Channel.new(:application_id => app.id, :name => 'chan3', :protocol => 'protocol', :kind => 'smtp')
    chan3.configuration = {:host => 'the_host', :port => 123, :user => 'the_user', :password => 'the_password', :use_ssl => '1'}
    chan3.save
  
    ReceiveTwitterMessageJob.enqueue_for_all_channels
    
    jobs = Delayed::Job.all
    assert_equal 2, jobs.length
    
    job = YAML::load jobs[0].handler
    assert_equal 'ReceiveTwitterMessageJob', job.class.to_s
    assert_equal app.id, job.application_id
    assert_equal chan1.id, job.channel_id
    
    job = YAML::load jobs[1].handler
    assert_equal 'ReceiveTwitterMessageJob', job.class.to_s
    assert_equal app.id, job.application_id
    assert_equal chan2.id, job.channel_id
  end
  
end