class ThrottledWorker

  def perform
    chans = Channel.all(:conditions => 'throttle is not null')
    chans.each do |chan|
      running_count = Delayed::Job.count(:conditions => ['channel_id = ? AND failed_at is null', chan.id])
      available_count = chan.throttle - running_count
      if available_count > 0
        jobs = ThrottledJob.all(:conditions => ['channel_id = ?', chan.id], :limit => available_count)
        if jobs.length > 0
          jobs.each do |job|
            Delayed::Job::enqueue_with_channel_id chan.id, job.payload_object 
          end
          ThrottledJob.delete_all(['id IN (?)', jobs.map{|j| j.id}])
        end
      end
    end
  end
  
end


