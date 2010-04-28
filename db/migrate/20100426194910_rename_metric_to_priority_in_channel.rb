class RenameMetricToPriorityInChannel < ActiveRecord::Migration
  def self.up
    rename_column :channels, :metric, :priority
  end

  def self.down
    rename_column :channels, :priority, :metric 
  end
end
