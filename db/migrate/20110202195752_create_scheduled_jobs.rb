class CreateScheduledJobs < ActiveRecord::Migration
  def self.up
    create_table :scheduled_jobs do |t|
      t.text :job
      t.datetime :run_at

      t.timestamps
    end

    add_index :scheduled_jobs, :run_at
  end

  def self.down
    drop_table :scheduled_jobs
  end
end
