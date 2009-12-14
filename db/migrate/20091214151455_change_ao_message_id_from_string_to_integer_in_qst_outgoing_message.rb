class ChangeAoMessageIdFromStringToIntegerInQstOutgoingMessage < ActiveRecord::Migration
  def self.up
    change_column :qst_outgoing_messages, :ao_message_id, :integer
  end

  def self.down
    change_column :qst_outgoing_messages, :ao_message_id, :string
  end
end
