class RemoveThreadFromApplicationLog < ActiveRecord::Migration
  def self.up
    remove_column :application_logs, :thread
  end

  def self.down
    add_column :application_logs, :thread, :string
  end
end
