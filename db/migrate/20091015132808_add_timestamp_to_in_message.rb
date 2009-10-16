class AddTimestampToInMessage < ActiveRecord::Migration
  def self.up
    add_column :in_messages, :timestamp, :timestamp
  end

  def self.down
    remove_column :in_messages, :timestamp
  end
end
