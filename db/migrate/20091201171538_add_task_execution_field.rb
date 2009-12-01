class AddTaskExecutionField < ActiveRecord::Migration
  def self.up
    add_column :cron_tasks, :code, :string, :null => true
  end

  def self.down
    remove_column :cron_tasks, :code
  end
end
