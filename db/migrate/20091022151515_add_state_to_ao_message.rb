class AddStateToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :state, :string, :default => 'pending', :null => false
  end

  def self.down
    remove_column :ao_messages, :state
  end
end
