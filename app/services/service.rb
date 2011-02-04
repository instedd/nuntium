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
          Rails.logger.error "Daemon failure: #{err} #{err.backtrace}"
        end
        sleep_seconds.times do
          sleep 1
          break if not running?
        end
      end
    end
  end

end
