class AddChannelIdToSmppMessagePart < ActiveRecord::Migration
  def self.up
    add_column :smpp_message_parts, :channel_id, :integer
    add_index :smpp_message_parts, [:channel_id, :reference_number]
  end

  def self.down
    remove_index :smpp_message_parts, [:channel_id, :reference_number]
    remove_column :smpp_message_parts, :channel_id
  end
end
