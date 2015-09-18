InsteddTelemetry.setup do |conf|
  conf.server_url = "http://localhost:3001"

  conf.add_collector Telemetry::ActiveChannelsCollector
  conf.add_collector Telemetry::AoCountCollector
  conf.add_collector Telemetry::AtCountCollector
  conf.add_collector Telemetry::ChannelsByTypeCollector
  conf.add_collector Telemetry::NumbersByCountryCodeCollector
end
