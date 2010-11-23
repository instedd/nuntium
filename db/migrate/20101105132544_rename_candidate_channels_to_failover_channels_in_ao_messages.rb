class RenameCandidateChannelsToFailoverChannelsInAoMessages < ActiveRecord::Migration
  def self.up
    rename_column :ao_messages, :candidate_channels, :failover_channels
  end

  def self.down
    rename_column :ao_messages, :failover_channels, :candidate_channels
  end
end
