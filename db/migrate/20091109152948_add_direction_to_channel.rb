class AddDirectionToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :direction, :int
  end

  def self.down
    remove_column :channels, :direction
  end
end
