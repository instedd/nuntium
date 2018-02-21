require 'lib/random_generator'

FactoryBot.define do
  factory :country, class: Country do
    name Faker::Address.country
    iso2 { RandomGenerator.iso2 }
    iso3 { RandomGenerator.iso3 }
    phone_prefix { RandomGenerator.phone_prefix }
  end
end
