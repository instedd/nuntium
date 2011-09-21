#!/usr/bin/env ruby
require(File.expand_path('../generic_daemon', __FILE__))
start_service 'smpp_service_daemon' do
  SmppService.new.start
  EM.reactor_thread.join
end
