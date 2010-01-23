class AddAtRoutingToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :at_routing, :string
  end

  def self.down
    remove_column :applications, :at_routing
  end
end
