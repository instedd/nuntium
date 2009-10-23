class AddProtocolToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :protocol, :string
  end

  def self.down
    remove_column :channels, :protocol
  end
end
