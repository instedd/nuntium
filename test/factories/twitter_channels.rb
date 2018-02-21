require 'lib/random_generator'

FactoryBot.define do
  factory :twitter_channel, class: TwitterChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "twitter" }
    enabled { true }
    configuration { { token: RandomGenerator.guid, secret: RandomGenerator.guid, screen_name: Faker::Internet.user_name } }
  end
end
