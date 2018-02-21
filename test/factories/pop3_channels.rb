require 'lib/random_generator'

FactoryBot.define do
  factory :pop3_channel, class: Pop3Channel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Incoming }
    protocol { "mailto" }
    enabled { true }
    configuration {
      {
        host: Faker::Internet.domain_name,
        port: rand(1000) + 1,
        user: Faker::Internet.user_name,
        password: Faker::Internet.password,
      }
    }
  end
end
