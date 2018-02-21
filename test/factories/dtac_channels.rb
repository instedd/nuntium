require 'lib/random_generator'

FactoryBot.define do
  factory :dtac_channel, class: DtacChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    configuration { { user: Faker::Internet.user_name, password: Faker::Internet.password } }
  end
end
