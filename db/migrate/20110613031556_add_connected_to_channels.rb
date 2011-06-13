class AddConnectedToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :connected, :boolean
  end

  def self.down
    remove_column :channels, :connected
  end
end
