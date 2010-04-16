#!/usr/bin/ruby
require(File.join(File.dirname(__FILE__), 'generic_daemon'))
start_service 'alert_service_daemon' do
  AlertService.new.start
end
