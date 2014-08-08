class AddIndexForChannelsOnAccountIdAndName < ActiveRecord::Migration
  def up
    add_index :channels, [:account_id, :name]
  end

  def down
    remove_index :channels, [:account_id, :name]
  end
end
