require 'machinist/active_record'
require 'sham'

Sham.name { Faker::Name.name }
Sham.password { Faker::Name.name }
Sham.iso2 { (1..2).map { ('a'..'z').to_a.rand }.join }
Sham.iso3 { (1..3).map { ('a'..'z').to_a.rand }.join }
Sham.phone_prefix { (1..2).map { ('0'..'9').to_a.rand }.join }
Sham.prefixes { (1..2).map { ('0'..'9').to_a.rand }.join }
Sham.guid { (1..10).map { ('a'..'z').to_a.rand }.join }
Sham.from { "sms://" + (1..8).map { ('0'..'9').to_a.rand }.join }
Sham.to { "sms://" + (1..8).map { ('0'..'9').to_a.rand }.join }
Sham.subject { Faker::Lorem.sentence }
Sham.body { Faker::Lorem.paragraph }

Account.blueprint do
  name
  password
  password_confirmation { password }
end

Application.blueprint do
  name
  account
  interface { "rss" }
  configuration { {:use_address_source => '1'} }
  password
  password_confirmation { password }
end

[AOMessage, ATMessage].each do |message|
  message.blueprint do
    from
    to
    subject
    body
  end
end

Country.blueprint do
  name
  iso2
  iso3
  phone_prefix
end

Carrier.blueprint do
  country
  name
  guid
  prefixes
end
