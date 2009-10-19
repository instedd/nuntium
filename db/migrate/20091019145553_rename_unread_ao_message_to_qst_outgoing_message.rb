class RenameUnreadAoMessageToQstOutgoingMessage < ActiveRecord::Migration
  def self.up
    rename_table :unread_ao_messages, :qst_outgoing_messages
  end

  def self.down
    rename_table :qst_outgoing_messages, :unread_ao_messages 
  end
end
