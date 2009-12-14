class AddChannelRelativeIdToAtMessages < ActiveRecord::Migration
  def self.up
    add_column :at_messages, :channel_relative_id, :string
  end

  def self.down
    remove_column :at_messages, :channel_relative_id
  end
end
