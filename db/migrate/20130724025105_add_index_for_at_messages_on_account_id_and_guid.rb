class AddIndexForAtMessagesOnAccountIdAndGuid < ActiveRecord::Migration
  def up
    add_index :at_messages, [:account_id, :guid]
  end

  def down
    remove_index :at_messages, [:account_id, :guid]
  end
end
