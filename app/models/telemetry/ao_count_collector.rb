module Telemetry::AoCountCollector
  def self.collect_stats(period)
    ao_messages = AoMessage.where('created_at < ?', period.end).count

    {
      counters: [
        {
          metric: 'ao_messages',
          key: {},
          value: ao_messages
        }
      ]
    }
  end
end
