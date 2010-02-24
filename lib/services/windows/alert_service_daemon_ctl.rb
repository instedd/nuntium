require 'daemon_ctl'

class AlertServiceDaemonController

  extend DaemonController

  @service_name = 'NuntiumAlertService'
  @service_displayname = 'Nuntium Alert Service'
  @service_file = 'alert_service_daemon.rb'
  @service_description = 'Sends nuntium alert notifications'
  @service_parameters = ARGV[1..-1] || []
  
end

AlertServiceDaemonController.run ARGV[0]
