#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
start_service 'managed_processes_daemon' do
  ManagedProcessesService.new.start
  EM.reactor_thread.join
end
