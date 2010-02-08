class AddThrottleToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :throttle, :int
  end

  def self.down
    remove_column :channels, :throttle
  end
end
