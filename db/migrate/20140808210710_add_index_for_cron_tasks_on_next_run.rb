class AddIndexForCronTasksOnNextRun < ActiveRecord::Migration
  def up
    add_index :cron_tasks, [:next_run]
  end

  def down
    remove_index :cron_tasks, [:next_run]
  end
end
