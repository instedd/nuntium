require 'lib/random_generator'

FactoryBot.define do
  factory :ipop_channel, class: IpopChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    address { RandomGenerator.number8 }
    configuration { { mt_post_url: Faker::Internet.domain_name, bid: '1', cid: RandomGenerator.number8 } }
  end
end
