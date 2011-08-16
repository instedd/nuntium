def start_service(log_name)
  $log_path = File.join(File.dirname(__FILE__), '..', '..', 'log', "#{log_name}.log")
  Rails.env = ARGV[0] unless ARGV.empty?

  require(File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot'))
  require(File.join(Rails.root, 'config', 'environment'))

  yield
rescue Exception => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}\n" }
end
