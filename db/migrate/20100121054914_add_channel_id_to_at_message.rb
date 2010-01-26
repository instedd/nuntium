class AddChannelIdToAtMessage < ActiveRecord::Migration
  def self.up
    add_column :at_messages, :channel_id, :integer
  end

  def self.down
    remove_column :at_messages, :channel_id
  end
end
