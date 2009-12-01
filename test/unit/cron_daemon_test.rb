require "test/unit"
require "lib/services/cron_daemon"

class CronDaemonTest < ActiveSupport::TestCase
  
  include CronDaemonRun
  
  test "invoke cron run" do
    cron_run
  end
  
end