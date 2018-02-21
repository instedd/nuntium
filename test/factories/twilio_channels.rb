require 'lib/random_generator'

FactoryBot.define do
  factory :twilio_channel, class: TwilioChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    configuration {
      {
        account_sid: RandomGenerator.guid,
        auth_token: RandomGenerator.guid,
        from: RandomGenerator.number8,
        incoming_password: Faker::Internet.password
      }
    }
  end
end
