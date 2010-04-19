class Service

  def initialize
    @is_running = true
    
    @previous_trap = trap("TERM") do
      stop
      Thread.new do
        Thread.main.join(5)
        @previous_trap.call if @previous_trap
      end
    end
  end
  
  def running?
    @is_running
  end
  
  def daydream(seconds)
    start = Time.now.to_i
    while running? && (Time.now.to_i - start) < seconds
      sleep 1
    end
  end
  
  def logger
    Rails.logger
  end
  
  def stop
    @is_running = false
  end
  
  # Defines a start method that executes the given block and sleeps
  # sleep_seconds. Repeats this for ever. Takes care of exceptions.
  def self.loop_with_sleep(sleep_seconds, &block)
    raise 'no block given for loop_with_sleep' if not block_given?
    define_method('start') do
      while running?
        begin
          instance_eval(&block)
        rescue Exception => err
          logger.error "Daemon failure: #{err} #{err.backtrace}"
        end
        daydream sleep_seconds
      end
    end
  end

end
