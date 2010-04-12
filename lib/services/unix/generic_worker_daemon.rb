#!/usr/bin/ruby
$log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', "generic_worker_daemon_#{ARGV[1]}.log")
ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

begin
  require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))

  GenericWorkerService.new(nil, ARGV[1]).start
  EM.reactor_thread.join
rescue Exception => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}\n" }
end
