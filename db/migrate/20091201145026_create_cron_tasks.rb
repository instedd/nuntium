class CreateCronTasks < ActiveRecord::Migration
  def self.up
    create_table :cron_tasks do |t|
      t.integer :interval
      t.datetime :next_run
      t.datetime :last_run

      t.timestamps
    end
  end

  def self.down
    drop_table :cron_tasks
  end
end
