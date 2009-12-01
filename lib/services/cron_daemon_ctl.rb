require 'daemon_ctl'

class DelayedJobDaemonController

  extend DaemonController

  @service_name = 'NuntiumCron'
  @service_displayname = 'Nuntium Cron'
  @service_file = 'cron_daemon.rb'
  @service_description = 'Cron for nuntium scheduled tasks'
  @service_parameters = ARGV[1] || 'production'
  
end

DelayedJobDaemonController.run ARGV[0]
