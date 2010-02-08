module Delayed
  class Job
    # Add a job to the queue with channel_id as the first argument
    def self.enqueue_with_channel_id(*args)
      channel_id = args.shift
    
      object = args.shift
      unless object.respond_to?(:perform)
        raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
      end

      priority = args.first || 0
      run_at = args[1]
      self.create(:channel_id => channel_id, :payload_object => object, :priority => priority.to_i, :run_at => run_at)
    end
  end
end
