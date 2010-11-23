class AddCostToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :ao_cost, :decimal, :limit => 10, :precision => 10, :scale => 2
    add_column :channels, :at_cost, :decimal, :limit => 10, :precision => 10, :scale => 2
  end

  def self.down
    remove_column :channels, :at_cost
    remove_column :channels, :ao_cost
  end
end
