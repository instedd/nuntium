module Telemetry::ChannelsByTypeCollector
  def self.collect_stats(period)
    channels_by_kind = Channel.where('created_at < ?', period.end).group(:kind).count
    counters = channels_by_kind.map do |kind, count|
      {
        type: 'channels_by_type',
        key: {type: kind},
        value: count
      }
    end

    {counters: counters}
  end
end
