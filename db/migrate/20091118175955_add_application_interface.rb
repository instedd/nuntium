class AddApplicationInterface < ActiveRecord::Migration
  def self.up
    add_column :applications, :interface, :string, :default => 'rss'
    add_column :applications, :configuration, :string
  end

  def self.down
    remove_column :applications, :interface
    remove_column :applications, :configuration
  end
end
