class CreateUserChannels < ActiveRecord::Migration
  def change
    create_table :user_channels do |t|
      t.integer :account_id
      t.integer :user_id
      t.integer :channel_id
      t.string :role

      t.timestamps
    end
  end
end
