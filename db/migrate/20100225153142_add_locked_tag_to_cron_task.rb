class AddLockedTagToCronTask < ActiveRecord::Migration
  def self.up
    add_column :cron_tasks, :locked_tag, :string
  end

  def self.down
    remove_column :cron_tasks, :locked_tag
  end
end
