#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), 'generic_ctl'))
if ARGV.length != 5
  puts "Usage: ./generic_worker_daemon_ctl.rb start -- <environment> <working_group> <instance_id>"
else
  run('generic_worker_daemon', "#{ARGV[3]}.#{ARGV[4]}")
end
