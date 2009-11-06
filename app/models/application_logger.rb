class ApplicationLogger < Logger
  def initialize(application)
    dir = File.join(RAILS_ROOT, 'log', application.name)
    Dir.mkdir(dir) if !File.exists?(dir)
    super(File.join(RAILS_ROOT, 'log', application.name, 'app.log'), 'daily')
  end
  
  def protocol_not_found_for(msg)
    self.warn '[POST /rss] Protocol not found for #{msg.inspect}'
  end
  
  def no_channel_found_for(protocol, msg)
    self.warn '[POST /rss] No channel found for protocol "#{protocol}" for message "#{msg.inspect}"'
  end
  
  def more_than_one_channel_found_for(protocol, msg)
    app_logger.warn '[POST /rss] More than one channel found for protocol "#{protocol} for message "#{msg.inspect}"'
  end
  
  def format_message(severity, timestamp, progname, msg)
    "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n" 
  end
end