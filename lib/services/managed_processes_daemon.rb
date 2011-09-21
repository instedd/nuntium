#!/usr/bin/env ruby
require(File.expand_path('../generic_daemon', __FILE__))
start_service 'managed_processes_daemon' do
  ManagedProcessesService.new.start
  EM.reactor_thread.join
end
