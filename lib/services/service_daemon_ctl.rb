#!/usr/bin/ruby
require(File.expand_path('../generic_ctl', __FILE__))
if ARGV.length != 4
  puts "Usage: ./service_daemon_ctl.rb start -- <environment> <channel_id>"
else
  run('service_daemon', ARGV[3])
end
