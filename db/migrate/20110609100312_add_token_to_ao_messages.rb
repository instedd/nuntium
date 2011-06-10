class AddTokenToAoMessages < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :token, :string, :limit => 36 # It's a Guid
  end

  def self.down
    remove_column :ao_messages, :token
  end
end
