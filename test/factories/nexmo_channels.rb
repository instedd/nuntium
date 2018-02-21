require 'lib/random_generator'

FactoryBot.define do
  factory :nexmo_channel, class: NexmoChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    configuration {
      {
        from: RandomGenerator.number8,
        api_key: Faker::Internet.user_name,
        api_secret: Faker::Internet.password,
      }
    }
  end
end
