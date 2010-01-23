class AddAoRoutingToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :ao_routing, :string
  end

  def self.down
    remove_column :applications, :ao_routing
  end
end
