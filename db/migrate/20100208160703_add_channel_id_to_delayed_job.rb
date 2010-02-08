class AddChannelIdToDelayedJob < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :channel_id, :integer
  end

  def self.down
    remove_column :delayed_jobs, :channel_id
  end
end
