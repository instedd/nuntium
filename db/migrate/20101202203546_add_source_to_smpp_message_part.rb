class AddSourceToSmppMessagePart < ActiveRecord::Migration
  def self.up
    add_column :smpp_message_parts, :source, :string
    remove_index :smpp_message_parts, [:channel_id, :reference_number]
    add_index :smpp_message_parts, [:channel_id, :source, :reference_number], :name => 'index_smpp_message_parts'
  end

  def self.down
    remove_index :smpp_message_parts, :name => 'index_smpp_message_parts'
    remove_column :smpp_message_parts, :source
    add_index :smpp_message_parts, [:channel_id, :reference_number]
  end
end
