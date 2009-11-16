class CreateTwitterChannelStatuses < ActiveRecord::Migration
  def self.up
    create_table :twitter_channel_statuses do |t|
      t.references :channel
      t.integer :last_id

      t.timestamps
    end
  end

  def self.down
    drop_table :twitter_channel_statuses
  end
end
