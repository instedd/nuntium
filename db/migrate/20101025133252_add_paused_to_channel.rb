class AddPausedToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :paused, :boolean, :default => 0
  end

  def self.down
    remove_column :channels, :paused
  end
end
