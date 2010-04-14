#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
if ARGV.length != 2
  puts "Usage: ./generic_worker_daemon.rb <environment> <instance_id>"
else
  start_service "generic_worker_daemon_#{ARGV[1]}" do
    GenericWorkerService.new(ARGV[1]).start
    EM.reactor_thread.join
  end
end
