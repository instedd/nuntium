require 'daemon_ctl'

class SmppGatewayDaemonController

  extend DaemonController

  # ARGV[0]: Option, ARGV[1]: Environment, ARGV[2]: ChannelId
  @service_name = 'NuntiumSMPPGateway' + ARGV[2] 
  @service_displayname = 'Nuntium SMPP Gateway ' + ARGV[2]
  @service_file = 'drb_smpp_daemon.rb'
  @service_description = 'SMPP Gateway'
  @service_parameters = ARGV[1..-1] || []
  
end

SmppGatewayDaemonController.run ARGV[0]
