class AlertService < Service

  loop_with_sleep(5 * 60) do
    @interpreter ||= AlertInterpreter.new
    @sender ||= AlertSender.new
    
    # Run alert logic
    begin
      Application.all.each { |app| @interpreter.interpret_for app }
    rescue Exception => err
      logger.error "Daemon failure when running scripts: #{err} #{err.backtrace}"
    end
    
    # Send pending alerts
    begin
      @sender.perform
    rescue Exception => err
      logger.error "Daemon failure when sending alerts: #{err} #{err.backtrace}"
    end
  end

end
