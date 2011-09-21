#!/usr/bin/ruby
require(File.expand_path('../generic_daemon', __FILE__))
start_service 'scheduled_jobs_service_daemon' do
  ScheduledJobsService.new.start
  EM.reactor_thread.join
end

