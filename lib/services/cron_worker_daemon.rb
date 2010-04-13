#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
if ARGV.length != 2
  puts "Usage: ./cron_worker_daemon.rb <environment> <instance_id>"
else
  start_service "cron_worker_daemon_#{ARGV[1]}" do
    CronWorkerService.new.start
    EM.reactor_thread.join
  end
end
