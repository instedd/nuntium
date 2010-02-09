class CreateAlerts < ActiveRecord::Migration
  def self.up
    create_table :alerts do |t|
      t.integer :application_id
      t.integer :channel_id
      t.string :kind
      t.integer :ao_message_id
      t.timestamp :sent_at

      t.timestamps
    end
  end

  def self.down
    drop_table :alerts
  end
end
