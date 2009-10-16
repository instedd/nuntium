class CreateUnreadOutMessages < ActiveRecord::Migration
  def self.up
    create_table :unread_out_messages do |t|
      t.string :guid

      t.timestamps
    end
  end

  def self.down
    drop_table :unread_out_messages
  end
end
