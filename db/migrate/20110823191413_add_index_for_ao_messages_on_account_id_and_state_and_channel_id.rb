class AddIndexForAoMessagesOnAccountIdAndStateAndChannelId < ActiveRecord::Migration
  def self.up
    add_index :ao_messages, [:account_id, :state, :channel_id]
  end

  def self.down
    remove_index :ao_messages, [:account_id, :state, :channel_id]
  end
end
