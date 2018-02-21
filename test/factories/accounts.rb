FactoryBot.define do
  factory :account, class: Account do
    name Faker::Name.name
    password Faker::Internet.password
    password_confirmation { password }
  end
end
