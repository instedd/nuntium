class AddIndexChannelIdToThrottledJobs < ActiveRecord::Migration
  def self.up
    add_index :throttled_jobs, :channel_id
  end

  def self.down
    remove_index :throttled_jobs, :channel_id
  end
end
