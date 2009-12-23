require 'daemon_ctl'


class DelayedJobDaemonController

  extend DaemonController

  @service_name = 'NuntiumWorker'
  @service_displayname = 'Nuntium Worker'
  @service_file = 'delayed_job_daemon.rb'
  @service_description = 'Runs nuntium jobs in a delayed queue'
  @service_parameters = ARGV[1] || ''
  
end

DelayedJobDaemonController.run ARGV[0]
