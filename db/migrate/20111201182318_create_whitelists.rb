class CreateWhitelists < ActiveRecord::Migration
  def self.up
    create_table :whitelists do |t|
      t.integer :account_id
      t.integer :channel_id
      t.string :address

      t.timestamps
    end

    add_index :whitelists, [:account_id, :channel_id, :address]
  end

  def self.down
    drop_table :whitelists
  end
end
