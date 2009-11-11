class AddServerityToApplicationLog < ActiveRecord::Migration
  def self.up
    add_column :application_logs, :severity, :int
  end

  def self.down
    remove_column :application_logs, :severity
  end
end
