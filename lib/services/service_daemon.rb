#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
if ARGV.length != 2
  puts "Usage: ./service_daemon.rb <environment> <channel_id>"
else
  start_service "service_daemon_#{ARGV[1]}" do
    begin
      channel_id = ARGV[1]
      channel = Channel.find_by_id channel_id
      if channel
        channel.service.start
        EM.reactor_thread.join
      else
        Rails.logger.error "No channel found for id #{channel_id}"
      end
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      exit -1
    end
  end
end
