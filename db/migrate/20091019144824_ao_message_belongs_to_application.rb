class AoMessageBelongsToApplication < ActiveRecord::Migration
  def self.up
    change_table :ao_messages do |t|
      t.references :application
    end
  end

  def self.down
    remove_column :ao_messages, :application_id
  end
end
