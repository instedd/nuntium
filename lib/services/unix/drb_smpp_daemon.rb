#!/usr/bin/ruby
$log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'drb_smpp_daemon.log')
ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
require(File.join(RAILS_ROOT, 'config', 'environment'))

require(File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'services', 'drb_smpp_client'))

trap("INT") { stopSMPPGateway; exit }
trap("EXIT") { stopSMPPGateway; exit }
      
channel_id = ARGV[1] unless ARGV.empty?   

startSMPPGateway(channel_id)

while true
  sleep 1
end
