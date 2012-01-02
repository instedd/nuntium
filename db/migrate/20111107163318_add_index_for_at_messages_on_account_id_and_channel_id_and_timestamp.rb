class AddIndexForAtMessagesOnAccountIdAndChannelIdAndTimestamp < ActiveRecord::Migration
  def self.up
    add_index :at_messages, [:account_id, :channel_id, :timestamp]
  end

  def self.down
    remove_index :at_messages, [:account_id, :channel_id, :timestamp]
  end
end
