class AddGuidToOutMessage < ActiveRecord::Migration
  def self.up
    add_column :out_messages, :guid, :string
  end

  def self.down
    remove_column :out_messages, :guid
  end
end
