require 'lib/random_generator'

FactoryBot.define do
  factory :clickatell_channel, class: ClickatellChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    configuration {
      {
        user: Faker::Internet.user_name,
        password: Faker::Internet.password,
        api_id: RandomGenerator.guid,
        from: RandomGenerator.number8,
        incoming_password: Faker::Internet.password,
        cost_per_credit: RandomGenerator.number2
      }
    }
  end
end



