require 'lib/random_generator'

FactoryBot.define do
  factory :shujaa_channel, class: ShujaaChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    address { RandomGenerator.number8 }
    configuration { { username: Faker::Internet.user_name, password: Faker::Internet.password, shujaa_account: 'live' } }
  end
end
