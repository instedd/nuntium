module Telemetry::AtCountCollector
  def self.collect_stats(period)
    at_messages = AtMessage.where('created_at < ?', period.end).count

    {
      counters: [
        {
          metric: 'at_messages',
          key: {},
          value: at_messages
        }
      ]
    }
  end
end
