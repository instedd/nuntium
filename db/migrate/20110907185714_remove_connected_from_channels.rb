class RemoveConnectedFromChannels < ActiveRecord::Migration
  def self.up
    remove_column :channels, :connected
  end

  def self.down
    add_column :channels, :connected, :boolean
  end
end
