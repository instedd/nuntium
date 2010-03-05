class ManagedProcess < ActiveRecord::Base
  
  # Returns the status of all the managed processes in comparison to a previous
  # status returned by this same function. The status is a hash where keys
  # are ManagedProcess and values are :start, :stop and :restart if the
  # process should be started, stopped or restarted respectly.
  def self.status(previous_status = nil)
    if previous_status.nil?
      ManagedProcess.all.inject({}) { |h, o| h[o] = :start; h }
    else
      # Keep previous alive processes
      # See: http://www.softiesonrails.com/2007/9/18/ruby-201-weird-hash-syntax
      previous_status = Hash[*previous_status.select{|k, v| v != :stop}.flatten]
      new_status = {}
      
      # Check new and newer/enabled/disabled processes
      procs = ManagedProcess.all
      procs.each do |proc|
        prev = previous_status.select{|k, v| k == proc}
        prev = prev.empty? ? nil : prev[0][0]
        next new_status[proc] = :start if prev.nil?
        next new_status[proc] = :start if proc.enabled and !prev.enabled
        next new_status[proc] = :stop if !proc.enabled and prev.enabled
        next new_status[proc] = :restart if proc.updated_at > prev.updated_at
      end
      
      # Check processes to delete
      previous_status.select{|k, v| not procs.include? k}.each do |k, v|
        new_status[k] = :stop
      end
      
      new_status
    end
  end
end
