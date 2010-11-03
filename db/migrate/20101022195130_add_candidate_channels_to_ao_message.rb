class AddCandidateChannelsToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :candidate_channels, :text
  end

  def self.down
    remove_column :ao_messages, :candidate_channels
  end
end
