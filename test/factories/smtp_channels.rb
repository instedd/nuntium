require 'lib/random_generator'

FactoryBot.define do
  factory :smtp_channel, class: SmtpChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Outgoing }
    protocol { "mailto" }
    enabled { true }

    configuration {
      {
        user: Faker::Internet.user_name,
        password: Faker::Internet.password,
        host: Faker::Internet.domain_name,
        port: 1 + rand(1000),
      }
    }
  end
end
