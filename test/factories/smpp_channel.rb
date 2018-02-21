require 'lib/random_generator'

FactoryBot.define do
  factory :smpp_channel, class: SmppChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Outgoing }
    protocol { "sms" }
    enabled { true }
    configuration {
      {
        user: Faker::Internet.user_name,
        password: Faker::Internet.password,
        host: Faker::Internet.domain_name,
        port: 1 + rand(1000),
        source_ton: 0,
        source_npi: 0,
        destination_ton: 0,
        destination_npi: 0,
        system_type: 'smpp',
        mt_encodings: ['ascii'],
        default_mo_encoding: 'ascii',
        mt_csms_method: 'udh'
      }
    }
  end
end
