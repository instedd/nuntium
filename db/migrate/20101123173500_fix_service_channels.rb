class FixServiceChannels < ActiveRecord::Migration
  def self.up
    Channel.all.each do |chan|
      next unless chan.handler.kind_of? ServiceChannelHandler

      chan.handler.on_destroy if chan.enabled
      chan.handler.on_create
    end
  end

  def self.down
  end
end
