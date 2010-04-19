#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
start_service 'cron_daemon' do
  CronService.new.start
end
