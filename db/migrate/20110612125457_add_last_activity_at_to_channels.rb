class AddLastActivityAtToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :last_activity_at, :datetime
  end

  def self.down
    remove_column :channels, :last_activity_at
  end
end
