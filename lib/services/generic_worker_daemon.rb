#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
if ARGV.length != 3
  puts "Usage: ./generic_worker_daemon.rb <environment> <working_group> <instance_id>"
else
  start_service "generic_worker_daemon_#{ARGV[1]}_#{ARGV[2]}" do
    GenericWorkerService.new(ARGV[2], ARGV[1]).start
    EM.reactor_thread.join
  end
end
