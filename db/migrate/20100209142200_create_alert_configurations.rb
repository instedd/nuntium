class CreateAlertConfigurations < ActiveRecord::Migration
  def self.up
    create_table :alert_configurations do |t|
      t.integer, :application_id
      t.integer, :channel_id
      t.string, :from
      t.string :to

      t.timestamps
    end
  end

  def self.down
    drop_table :alert_configurations
  end
end
