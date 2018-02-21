require 'lib/random_generator'

FactoryBot.define do
  factory :ticket, class: Ticket do
    code { RandomGenerator.number4 }
    secret_key { RandomGenerator.guid }

    factory :ticket_pending do
      status { 'pending' }
    end
  end
end
