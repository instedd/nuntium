require 'lib/random_generator'

FactoryBot.define do
  factory :qst_client_channel, class: QstClientChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    configuration { { url: Faker::Internet.domain_name, user: Faker::Internet.user_name, password: Faker::Internet.password } }
  end

  factory :qst_server_channel, class: QstServerChannel do
    account
    name { RandomGenerator.guid }
    direction { Channel::Bidirectional }
    protocol { "sms" }
    enabled { true }
    address { RandomGenerator.number8 }
    configuration { { password: 'secret', password_confirmation: 'secret' } }
  end
end



