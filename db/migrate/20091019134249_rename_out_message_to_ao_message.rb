class RenameOutMessageToAoMessage < ActiveRecord::Migration
  def self.up
    rename_table :out_messages, :ao_messages
  end

  def self.down
    rename_table :ao_messages, :out_messages
  end
end
