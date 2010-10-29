class ReEnableServiceChannels < ActiveRecord::Migration
  def self.up
    Channel.all(:conditions => ["enabled = ? AND (kind = ? OR kind = ?)", true, 'smpp', 'xmpp']).each do |chan|
      [false, true].each do |e|
        chan.enabled = e
        chan.save!
      end
    end
  end

  def self.down
  end
end
