module Telemetry::AtCountCollector
  def self.collect_stats(period)
    at_by_channel = AtMessage.where('created_at < ?', period.end).group(:channel_id).count

    counters = at_by_channel.map do |channel_id, count|
      {
        metric: 'at_messages',
        key: {channel_id: channel_id},
        value: count
      }
    end

    {counters: counters}
  end
end
