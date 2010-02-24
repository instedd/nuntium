class ThrottledService < Service

  def start
    worker = ThrottledWorker.new
    while running?
      begin
        worker.perform
      rescue Exception => err
        logger.error "Daemon failure: #{err} #{err.backtrace}"   
      ensure
        daydream 60
      end
    end
  end

end
