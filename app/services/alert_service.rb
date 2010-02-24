class AlertService < Service

  def start
    interpreter = AlertInterpreter.new
    sender = AlertSender.new
    while running?
      # Run alert logic
      begin
        Application.all.each { |app| interpreter.interpret_for app }
      rescue Exception => err
        logger.error "Daemon failure when running scripts: #{err} #{err.backtrace}"
      end
      
      # Send pending alerts
      begin
        sender.perform
      rescue Exception => err
        logger.error "Daemon failure when sending alerts: #{err} #{err.backtrace}"
      end
      
      # Wait 5 minutes
      daydream 5 * 60
    end
  end

end
