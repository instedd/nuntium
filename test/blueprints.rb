require 'machinist/active_record'
require 'sham'

Sham.define do
  name { Faker::Name.name }
  password { Faker::Name.name }
  number2 { (1..2).map { ('0'..'9').to_a.rand }.join }
  number8 { (1..8).map { ('0'..'9').to_a.rand }.join }
  guid { (1..10).map { ('a'..'z').to_a.rand }.join }
end

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

Application.blueprint(:http_post_callback) do
  interface { "http_post_callback" }
  configuration { {:interface_url => Sham.guid, :interface_user => Sham.name, :interface_password => Sham.name} }
end

Application.blueprint(:broadcast) do
  configuration { {:use_address_source => '1', :strategy => 'broadcast'} }
end

[AOMessage, ATMessage].each do |message|
  message.blueprint do
    from { "sms://#{Sham.number8}" }
    to { "sms://#{Sham.number8}" }
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    state { 'pending' }
  end
end

Carrier.blueprint do
  country
  name
  guid
  prefixes { Sham.number2 }
end

Channel.blueprint do
  account
  name { (1..10).map { ('a'..'z').to_a.rand }.join }
  kind { "qst_server" }
  protocol { "sms" }
  direction { Channel::Bidirectional }
  configuration { {:password => 'secret', :password_confirmation => 'secret'} }
end

Channel.blueprint(:clickatell) do
  kind { "clickatell" }
  configuration { {:user => Sham.name, :password => Sham.password, :api_id => Sham.name, :from => Sham.number8, :incoming_password => Sham.password }}
end

Country.blueprint do
  name
  iso2 { (1..2).map { ('a'..'z').to_a.rand }.join }
  iso3 { (1..3).map { ('a'..'z').to_a.rand }.join }
  phone_prefix { Sham.number2 }
end
