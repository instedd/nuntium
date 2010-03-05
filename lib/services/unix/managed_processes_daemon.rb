#!/usr/bin/ruby
$log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'managed_processes_daemon.log')
ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

begin
  require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))

  ManagedProcessesService.new.start
rescue Exception => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}\n" }
end
