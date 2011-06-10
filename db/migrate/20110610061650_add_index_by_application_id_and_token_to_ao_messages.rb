class AddIndexByApplicationIdAndTokenToAoMessages < ActiveRecord::Migration
  def self.up
    add_index :ao_messages, [:application_id, :token]
  end

  def self.down
    remove_index :ao_messages, [:application_id, :token]
  end
end
