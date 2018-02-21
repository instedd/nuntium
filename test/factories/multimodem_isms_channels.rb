require 'lib/random_generator'

FactoryBot.define do
  factory :multimodem_isms_channel, class: MultimodemIsmsChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    configuration {
      {
        host: Faker::Internet.domain_name,
        port: rand(1000) + 1,
        user: Faker::Internet.user_name,
        password: Faker::Internet.password,
        time_zone: ActiveSupport::TimeZone.all.rand.name
      }
    }
  end
end
