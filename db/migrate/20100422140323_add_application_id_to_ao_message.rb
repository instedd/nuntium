class AddApplicationIdToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :application_id, :integer
  end

  def self.down
    remove_column :ao_messages, :application_id
  end
end
