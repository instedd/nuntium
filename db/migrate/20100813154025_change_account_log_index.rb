class ChangeAccountLogIndex < ActiveRecord::Migration
  def self.up
    remove_index :account_logs, [:account_id, :created_at]
    add_index :account_logs, [:account_id, :id]
  end

  def self.down
    remove_index :account_logs, [:account_id, :id]
    add_index :account_logs, [:account_id, :created_at]
  end
end
