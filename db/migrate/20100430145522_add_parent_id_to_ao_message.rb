class AddParentIdToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :parent_id, :integer
  end

  def self.down
    remove_column :ao_messages, :parent_id
  end
end
