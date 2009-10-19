class RenameUnreadOutMessageToUnreadAoMessage < ActiveRecord::Migration
  def self.up
    rename_table :unread_out_messages, :unread_ao_messages
  end

  def self.down
    rename_table :unread_ao_messages, :unread_out_messages
  end
end
