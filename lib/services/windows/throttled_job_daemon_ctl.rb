require 'daemon_ctl'

class ThrottledJobDaemonController

  extend DaemonController

  @service_name = 'NuntiumThrottledWorker'
  @service_displayname = 'Nuntium Throttled Worker'
  @service_file = 'throttled_job_daemon.rb'
  @service_description = 'Runs throttled nuntium jobs'
  @service_parameters = ARGV[1..-1] || []
  
end

ThrottledJobDaemonController.run ARGV[0]
