class AddApplicationIdToAtMessage < ActiveRecord::Migration
  def self.up
    add_column :at_messages, :application_id, :integer
  end

  def self.down
    remove_column :at_messages, :application_id
  end
end
