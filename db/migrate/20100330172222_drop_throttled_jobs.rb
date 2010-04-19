class DropThrottledJobs < ActiveRecord::Migration
  def self.up
    drop_table :throttled_jobs
  end
  
  def self.down
    create_table :throttled_jobs do |t|
      t.integer :channel_id
      t.text :handler

      t.timestamps
    end
  end
end
