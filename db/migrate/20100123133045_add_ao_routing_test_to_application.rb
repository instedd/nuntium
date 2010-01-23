class AddAoRoutingTestToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :ao_routing_test, :string
  end

  def self.down
    remove_column :applications, :ao_routing_test
  end
end
