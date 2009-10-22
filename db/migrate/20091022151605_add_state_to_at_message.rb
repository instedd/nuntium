class AddStateToAtMessage < ActiveRecord::Migration
  def self.up
    add_column :at_messages, :state, :string, :default => 'pending', :null => false
  end

  def self.down
    remove_column :at_messages, :state
  end
end
