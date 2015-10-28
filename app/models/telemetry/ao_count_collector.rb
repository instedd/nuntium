module Telemetry::AoCountCollector
  def self.collect_stats(period)
    ao_by_channel = AoMessage.where('created_at < ?', period.end).group(:channel_id).count

    counters = ao_by_channel.map do |channel_id, count|
      {
        metric: 'ao_messages',
        key: {channel_id: channel_id},
        value: count
      }
    end

    {counters: counters}
  end
end
