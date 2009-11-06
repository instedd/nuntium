class ApplicationLogger < Logger
  def initialize(application)
    dir = File.join(RAILS_ROOT, 'log', application.name)
    Dir.mkdir(dir) if !File.exists?(dir)
    super(File.join(RAILS_ROOT, 'log', application.name, 'app.log'), 'daily')
  end
  
  def format_message(severity, timestamp, progname, msg)
    "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n" 
  end
end