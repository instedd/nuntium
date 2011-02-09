class ChangeTwitterChannelStatusesLastIdToString < ActiveRecord::Migration
  def self.up
    change_column :twitter_channel_statuses, :last_id, :string
  end

  def self.down
    change_column :twitter_channel_statuses, :last_id, :integer
  end
end
