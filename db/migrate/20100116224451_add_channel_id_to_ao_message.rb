class AddChannelIdToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :channel_id, :integer
  end

  def self.down
    remove_column :ao_messages, :channel_id
  end
end
