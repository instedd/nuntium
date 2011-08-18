class RenameAccountLogsToLogs < ActiveRecord::Migration
  def self.up
    rename_table :account_logs, :logs
  end

  def self.down
    rename_table :logs, :account_logs
  end
end
