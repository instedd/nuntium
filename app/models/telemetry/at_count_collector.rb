module Telemetry::AtCountCollector
  def self.collect_stats(period)
    period_end = ActiveRecord::Base.sanitize_sql(period.end)

    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT channels.id, COUNT(at_messages.channel_id)
      FROM channels
      LEFT JOIN at_messages ON at_messages.channel_id = channels.id
      AND at_messages.created_at < #{period_end}
      WHERE channels.created_at < #{period_end}
      GROUP BY channels.id
    SQL

    counters = results.map do |channel_id, count|
      {
        metric: 'at_messages',
        key: {channel_id: channel_id},
        value: count
      }
    end

    {counters: counters}
  end
end
