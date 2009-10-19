class AddGuidIndexToUnreadAoMessage < ActiveRecord::Migration
  def self.up
    add_index :unread_ao_messages, :guid
  end

  def self.down
    remove_index :unread_ao_messages, :guid
  end
end
