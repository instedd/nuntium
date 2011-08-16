class ReEnableServiceChannels < ActiveRecord::Migration
  def self.up
    Channel.where(:enabled => true, :kind => ['smpp', 'xmpp']).each do |chan|
      [false, true].each do |e|
        chan.enabled = e
        chan.save!
      end
    end
  end

  def self.down
  end
end
