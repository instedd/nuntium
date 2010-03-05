#!/usr/bin/ruby
$log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', "drb_smpp_daemon_#{ARGV[1]}.log")
ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

begin
  require(File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'services', 'drb_smpp_client'))

  ["INT", "EXIT", "TERM", "KILL"].each do |signal|
    trap(signal) { stopSMPPGateway; exit }
  end
        
  channel_id = ARGV[1] unless ARGV.empty?   

  startSMPPGateway(channel_id)

  while true
    sleep 1
  end
rescue Exception => err
  File.open($log_path, 'a') { |f| f.write "Daemon failure: #{err} #{err.backtrace}\n" }
end
