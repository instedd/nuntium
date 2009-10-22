class AddTriesToAtMessage < ActiveRecord::Migration
  def self.up
    add_column :at_messages, :tries, :int, :default => 0, :null => false
  end

  def self.down
    remove_column :at_messages, :tries
  end
end
