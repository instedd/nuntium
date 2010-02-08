class CreateThrottledJobs < ActiveRecord::Migration
  def self.up
    create_table :throttled_jobs do |t|
      t.integer, :channel_id
      t.text :handler

      t.timestamps
    end
  end

  def self.down
    drop_table :throttled_jobs
  end
end
