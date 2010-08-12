class AddAccountLogIndices < ActiveRecord::Migration
  def self.up
    add_index :account_logs, [:account_id, :created_at]
    add_index :account_logs, [:account_id, :ao_message_id]
    add_index :account_logs, [:account_id, :at_message_id]
  end

  def self.down
    remove_index :account_logs, [:account_id, :created_at]
    remove_index :account_logs, [:account_id, :ao_message_id]
    remove_index :account_logs, [:account_id, :at_message_id]
  end
end
