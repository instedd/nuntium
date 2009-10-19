class AddGuidIndexToAoMessage < ActiveRecord::Migration
  def self.up
    add_index :ao_messages, :guid
  end

  def self.down
    remove_index :ao_messages, :guid
  end
end
