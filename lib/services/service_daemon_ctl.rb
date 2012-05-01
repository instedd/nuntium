#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'generic_ctl'))
if ARGV.length != 4
  puts "Usage: ./service_daemon_ctl.rb start -- <environment> <channel_id>"
else
  run('service_daemon', ARGV[3])
end
