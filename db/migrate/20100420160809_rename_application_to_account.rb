class RenameApplicationToAccount < ActiveRecord::Migration

  RenamedTables = [
    :account_logs, 
    :address_sources, 
    :alerts,
    :alert_configurations, 
    :ao_messages, 
    :at_messages, 
    :channels,
    :managed_processes
    ]

  def self.up
    rename_table :applications, :accounts
    rename_table :application_logs, :account_logs
    
    RenamedTables.each do |t|
      rename_column t, :application_id, :account_id
    end
  end

  def self.down
    RenamedTables.each do |t|
      rename_column t, :account_id, :application_id
    end
    
    rename_table :account_logs, :application_logs
    rename_table :accounts, :applications
  end
end
