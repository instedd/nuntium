class AddAtRoutingTestToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :at_routing_test, :string
  end

  def self.down
    remove_column :applications, :at_routing_test
  end
end
