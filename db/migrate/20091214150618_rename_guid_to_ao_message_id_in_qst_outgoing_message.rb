class RenameGuidToAoMessageIdInQstOutgoingMessage < ActiveRecord::Migration
  def self.up
    rename_column :qst_outgoing_messages, :guid, :ao_message_id
  end

  def self.down
    rename_column :qst_outgoing_messages, :ao_message_id, :guid 
  end
end
