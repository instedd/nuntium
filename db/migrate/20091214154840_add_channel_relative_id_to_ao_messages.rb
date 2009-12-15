class AddChannelRelativeIdToAoMessages < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :channel_relative_id, :string
  end

  def self.down
    remove_column :ao_messages, :channel_relative_id
  end
end
