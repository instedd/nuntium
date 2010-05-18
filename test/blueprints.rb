require 'machinist/active_record'
require 'sham'

Sham.name { Faker::Name.name }
Sham.password { Faker::Name.name }

Account.blueprint do
  name
  password
  password_confirmation { password }
end
