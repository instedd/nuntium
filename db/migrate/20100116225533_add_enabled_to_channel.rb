class AddEnabledToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :enabled, :boolean, :default => 1
  end

  def self.down
    remove_column :channels, :enabled
  end
end
