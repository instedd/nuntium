class AddMetricToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :metric, :integer, :default => 100
  end

  def self.down
    remove_column :channels, :metric
  end
end
