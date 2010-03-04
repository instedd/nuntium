class AddIndexChannelIdChannelRelativeIdToAoMessages < ActiveRecord::Migration
  def self.up
    add_index :ao_messages, [:channel_id, :channel_relative_id]
  end

  def self.down
    remove_index :ao_messages, [:channel_id, :channel_relative_id]
  end
end
