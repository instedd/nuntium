class CreateManagedProcesses < ActiveRecord::Migration
  def self.up
    create_table :managed_processes do |t|
      t.integer :application_id
      t.string :name
      t.string :start_command
      t.string :stop_command
      t.string :pid_file
      t.string :log_file
      t.boolean :enabled, :deafault => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :managed_processes
  end
end
