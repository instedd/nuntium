class Service

  def initialize(controller = nil)
    @controller = controller
    
    if @controller.nil?
      trap("INT") { stop; exit }
      trap("EXIT") { stop; exit }
    end
  end
  
  def running?
    return true if @controller.nil?
    @controller.running?
  end
  
  def daydream(seconds)
    start = Time.now.to_i
    while running? && (Time.now.to_i - start) < seconds
      sleep 1
    end
  end
  
  def logger
    RAILS_DEFAULT_LOGGER
  end
  
  def stop
  end

end
