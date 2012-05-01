#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
start_service 'scheduled_jobs_service_daemon' do
  ScheduledJobsService.new.start
  EM.reactor_thread.join
end
