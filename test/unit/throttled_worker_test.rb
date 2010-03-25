require 'test_helper'

class ThrottledWorkerTest < ActiveSupport::TestCase

  test "do it" do
    worker = ThrottledWorker.new
  
    app = Application.create!(:name => 'app', :password => 'pass')
    chan = Channel.new(:application_id => app.id, :name => 'chan', :protocol => 'smpp', :kind => 'smpp')
    chan.configuration = {:host => 'the_host', :port => 3200, :source_ton => 0, :source_npi => 1, :destination_ton => 0, :destination_npi => 1, :user => 'the_user', :password => 'the_password', :use_latin1 => '0', :mt_encodings => ['ascii'], :system_type => 'smpp', :default_mo_encoding => 'ascii', :mt_csms_method => 'udh'}
    chan.throttle = 5
    chan.save!
    
    # Create 4 throttled jobs
    4.times { chan.handler.handle AOMessage.new(:application_id => app.id) }
    
    # Throttled jobs were created but no delayed job
    assert_equal 0, Delayed::Job.count
    assert_equal 4, ThrottledJob.count
    
    # When performing, execute those jobs
    worker.perform
    
    # Now all jobs "executing" and none pending
    assert_equal 4, Delayed::Job.count
    assert_equal 0, ThrottledJob.count
    
    ids = Delayed::Job.all(:select => :id)[0..-2].map(&:id)
    
    # The first four were taken
    Delayed::Job.all.each {|j| ids.include?(j.id)}
    
    # Create 4 more throttled jobs
    4.times { chan.handler.handle AOMessage.new(:application_id => app.id) }
    
    # Throttled jobs were created
    assert_equal 4, Delayed::Job.count
    assert_equal 4, ThrottledJob.count
    
    # When performing, execute reminaing job
    worker.perform
    
    assert_equal 5, Delayed::Job.count
    assert_equal 3, ThrottledJob.count
    
    # Mark 2 delayed_jobs as failed
    Delayed::Job.update_all(['failed_at = ?', Time.now], ['id <= ?', Delayed::Job.all[1]])
    
    # When performing we have place for 2 more jobs
    worker.perform
    
    assert_equal 7, Delayed::Job.count
    assert_equal 1, ThrottledJob.count
  end

end
