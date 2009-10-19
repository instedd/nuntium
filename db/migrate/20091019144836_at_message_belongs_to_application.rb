class AtMessageBelongsToApplication < ActiveRecord::Migration
  def self.up
    change_table :at_messages do |t|
      t.references :application
    end
  end

  def self.down
    remove_column :at_messages, :application_id
  end
end
