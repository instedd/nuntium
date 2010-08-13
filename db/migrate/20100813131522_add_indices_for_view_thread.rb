class AddIndicesForViewThread < ActiveRecord::Migration
  def self.up
    add_index :ao_messages, [:account_id, :to, :id]
    add_index :at_messages, [:account_id, :from, :id]
  end

  def self.down
    remove_index :ao_messages, [:account_id, :to, :id]
    remove_index :at_messages, [:account_id, :from, :id]
  end
end
