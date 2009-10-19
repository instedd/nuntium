class RenameInMessageToAtMessage < ActiveRecord::Migration
  def self.up
    rename_table :in_messages, :at_messages
  end

  def self.down
    rename_table :at_messages, :in_messages
  end
end
