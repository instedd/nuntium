class AddTriesToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :tries, :int, :default => 0, :null => false
  end

  def self.down
    remove_column :ao_messages, :tries
  end
end
