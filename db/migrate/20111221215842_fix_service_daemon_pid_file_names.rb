class FixServiceDaemonPidFileNames < ActiveRecord::Migration
  def self.up
    ManagedProcess.all.each do |proc|
      if proc.pid_file =~ /^service_daemon\.(\d+)\.pid$/
        proc.pid_file = "service_daemon.#{$1}..pid"
        proc.save!
      end
    end
  end

  def self.down
    ManagedProcess.all.each do |proc|
      if proc.pid_file =~ /^service_daemon\.(\d+)\.\.pid$/
        proc.pid_file = "service_daemon.#{$1}.pid"
        proc.save!
      end
    end
  end
end
