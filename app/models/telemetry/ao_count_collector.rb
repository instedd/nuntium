module Telemetry::AoCountCollector
  def self.collect_stats(period)
    period_end = ActiveRecord::Base.sanitize(period.end)

    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT channels.id, COUNT(ao_messages.channel_id)
      FROM channels
      LEFT JOIN ao_messages ON ao_messages.channel_id = channels.id
      AND ao_messages.created_at < #{period_end}
      WHERE channels.created_at < #{period_end}
      GROUP BY channels.id
    SQL

    counters = results.map do |channel_id, count|
      {
        metric: 'ao_messages',
        key: {channel_id: channel_id},
        value: count
      }
    end

    {counters: counters}
  end
end
