require 'lib/random_generator'

FactoryBot.define do
  factory :carrier, class: Carrier do
    country
    name Faker::Name.name
    guid RandomGenerator.guid
    prefixes RandomGenerator.number2
  end
end
