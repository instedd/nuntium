module Telemetry::ActiveChannelsCollector
  def self.collect_stats(period)
    active_channels = Channel.where('last_activity_at >= ? AND last_activity_at < ?', period.beginning, period.end).count

    {
      counters: [
        {
          metric: 'active_channels',
          key: {},
          value: active_channels
        }
      ]
    }
  end
end
