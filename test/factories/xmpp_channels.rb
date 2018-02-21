require 'lib/random_generator'

FactoryBot.define do
  factory :xmpp_channel, class: XmppChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "xmpp" }
    enabled { true }
    configuration {
      {
        user: Faker::Internet.user_name,
        password: Faker::Internet.password,
        domain: Faker::Internet.domain_name,
        port: 1 + rand(1000),
        resource: Faker::Internet.user_name,
      }
    }
  end
end
