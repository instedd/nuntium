#!/usr/bin/env ruby
require(File.expand_path('../generic_daemon', __FILE__))
start_service 'xmpp_service_daemon' do
  XmppService.new.start
  EM.reactor_thread.join
end
