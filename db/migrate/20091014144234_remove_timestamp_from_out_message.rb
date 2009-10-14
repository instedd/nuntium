class RemoveTimestampFromOutMessage < ActiveRecord::Migration
  def self.up
    remove_column :out_messages, :timestamp
  end

  def self.down
    add_column :out_messages, :timestamp, :timestamp
  end
end
