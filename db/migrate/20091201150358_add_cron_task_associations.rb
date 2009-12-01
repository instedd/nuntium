class AddCronTaskAssociations < ActiveRecord::Migration
  def self.up
    add_column :cron_tasks, :parent_id, :integer, :null => true 
    add_column :cron_tasks, :parent_type, :string, :limit => 60, :null => true 
  end

  def self.down
    remove_column :cron_tasks, :parent_id 
    remove_column :cron_tasks, :parent_type
  end
end
