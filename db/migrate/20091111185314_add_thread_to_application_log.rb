class AddThreadToApplicationLog < ActiveRecord::Migration
  def self.up
    add_column :application_logs, :thread, :string
  end

  def self.down
    remove_column :application_logs, :thread
  end
end
