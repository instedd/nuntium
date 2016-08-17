module Telemetry::NumbersByCountryCodeCollector
  def self.collect_stats(period)
    period_end = ActiveRecord::Base.sanitize(period.end)

    results = ActiveRecord::Base.connection.execute <<-SQL
      (SELECT ao.to FROM ao_messages ao WHERE ao.to IS NOT NULL AND ao.created_at < #{period_end})
      UNION
      (SELECT at.from FROM at_messages at WHERE at.from IS NOT NULL AND at.created_at < #{period_end})
    SQL

    numbers_by_country_code = Hash.new(0)

    results.each do |record|
      number = record.first
      protocol, address = number.protocol_and_address
      if protocol == 'sms'
        country_code = InsteddTelemetry::Util.country_code address
        numbers_by_country_code[country_code] += 1 if country_code.present?
      end
    end

    counters = numbers_by_country_code.map do |country_code, count|
      {
        metric: 'unique_phone_numbers_by_country',
        key: {country_code: country_code},
        value: count
      }
    end

    {counters: counters}
  end
end
