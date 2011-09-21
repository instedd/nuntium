#!/usr/bin/env ruby
require(File.expand_path('../generic_daemon', __FILE__))
start_service 'cron_daemon' do
  CronService.new.start
end
