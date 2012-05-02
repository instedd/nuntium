def start_service(log_name)
  $log_path = File.expand_path("../../../log/#{log_name}.log", __FILE__)
  ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

  require File.expand_path('../../../config/boot',  __FILE__)
  require File.expand_path('../../../config/environment',  __FILE__)

  yield
rescue SystemExit
  Rails.logger.info "Stopping service normally"
rescue Exception => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}\n" }
end
