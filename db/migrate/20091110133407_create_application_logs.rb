class CreateApplicationLogs < ActiveRecord::Migration
  def self.up
    create_table :application_logs do |t|
      t.references :application
      t.references :channel
      t.references :ao_message
      t.references :at_message
      t.text :message

      t.timestamps
    end
  end

  def self.down
    drop_table :application_logs
  end
end
