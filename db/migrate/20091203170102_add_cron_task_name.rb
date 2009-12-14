class AddCronTaskName < ActiveRecord::Migration
  def self.up
    add_column :cron_tasks, :name, :string, :null => true
  end

  def self.down
    remove_column :cron_tasks, :name
  end
end
