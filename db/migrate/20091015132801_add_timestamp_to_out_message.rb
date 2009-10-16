class AddTimestampToOutMessage < ActiveRecord::Migration
  def self.up
    add_column :out_messages, :timestamp, :timestamp
  end

  def self.down
    remove_column :out_messages, :timestamp
  end
end
