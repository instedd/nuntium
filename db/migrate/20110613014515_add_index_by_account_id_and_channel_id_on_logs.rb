class AddIndexByAccountIdAndChannelIdOnLogs < ActiveRecord::Migration
  def self.up
    add_index :account_logs, [:account_id, :channel_id]
  end

  def self.down
    remove_index :account_logs, [:account_id, :channel_id]
  end
end
