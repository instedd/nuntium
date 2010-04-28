class RemoveAlerts < ActiveRecord::Migration
  def self.up
    drop_table :alerts
    drop_table :alert_configurations
  end

  def self.down
    create_table :alerts do |t|
      t.integer :application_id
      t.integer :channel_id
      t.string :kind
      t.integer :ao_message_id
      t.timestamp :sent_at

      t.timestamps
    end
  
    create_table :alert_configurations do |t|
      t.integer :application_id
      t.integer :channel_id
      t.string :from
      t.string :to

      t.timestamps
    end
  end
end
