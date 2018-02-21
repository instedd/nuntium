require 'lib/random_generator'

FactoryBot.define do
  factory :msn_channel, class: MsnChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "msn" }
    enabled { true }
    configuration { { user: Faker::Internet.user_name, password: Faker::Internet.password } }
  end
end
