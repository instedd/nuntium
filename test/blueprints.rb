# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

require 'machinist/active_record'
require 'sham'

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  username { Faker::Internet.user_name }
  url { Faker::Internet.domain_name }
  password { Faker::Name.name }
  number2(:unique => false) { (1..2).map { ('1'..'9').to_a.rand }.join }
  number8 { (1..8).map { ('1'..'9').to_a.rand }.join }
  number4 { (1..4).map { ('1'..'9').to_a.rand }.join }
  guid { (1..10).map { ('a'..'z').to_a.rand }.join }
end

User.blueprint do
  email
  password
  password_confirmation { password }
  confirmed_at { Time.now - 1.day }
end

Account.blueprint do
  name { Sham.username }
  password
  password_confirmation { password }
end

Application.blueprint do
  name { Sham.username }
  account
  interface { "rss" }
  password
  password_confirmation { password }
end

Application.blueprint :rss do
end

Application.blueprint :broadcast do
  configuration { {:strategy => 'broadcast'} }
end

[:http_get_callback, :http_post_callback, :qst_client].each do |kind|
  Application.blueprint kind do
    interface { kind.to_s }
    configuration { {:interface_url => Sham.url, :interface_user => Sham.username, :interface_password => Sham.password} }
  end
end

[AoMessage, AtMessage].each do |message|
  message.blueprint do
    from { "sms://#{Sham.number8}" }
    to { "sms://#{Sham.number8}" }
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    timestamp { Time.at(946702800 + 86400 * rand(100)).getgm }
    guid
    state { 'queued' }
  end
  message.blueprint :email do
    from { "mailto://#{Sham.email}" }
    to { "mailto://#{Sham.email}" }
  end
end

Carrier.blueprint do
  country
  name
  guid
  prefixes { Sham.number2 }
end

QstClientChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:url => Sham.url, :user => Sham.username, :password => Sham.password} }
end

QstServerChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  address { Sham.number8 }
  configuration { {:password => 'secret', :password_confirmation => 'secret'} }
end

ClickatellChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:user => Sham.username, :password => Sham.password, :api_id => Sham.guid, :from => Sham.number8, :incoming_password => Sham.password, :cost_per_credit => rand }}
end

DtacChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:user => Sham.username, :password => Sham.password } }
end

IpopChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  address { Sham.number8 }
  configuration { {:mt_post_url => Sham.url, :bid => '1', :cid => Sham.number8 } }
end

MsnChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "msn" }
  enabled { true }
  configuration { {:email => Sham.email, :password => Sham.password } }
end

MultimodemIsmsChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration {{:host => Sham.url, :port => rand(1000) + 1, :user => Sham.username, :password => Sham.password, :time_zone => ActiveSupport::TimeZone.all.rand.name}}
end

Pop3Channel.blueprint do
  account
  name { Sham.guid }
  protocol { "mailto" }
  direction { Channel::Incoming }
  enabled { true }
  configuration { {:host => Sham.url, :port => rand(1000) + 1, :user => Sham.username, :password => Sham.password}}
end

ShujaaChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  address { Sham.number8 }
  configuration { {:username => Sham.username, :password => Sham.password, :shujaa_account => 'live' }}
end

SmtpChannel.blueprint do
  account
  name { Sham.guid }
  protocol { "mailto" }
  direction { Channel::Outgoing }
  enabled { true }
  configuration { {:host => Sham.url, :port => rand(1000) + 1, :user => Sham.username, :password => Sham.password}}
end

SmppChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration {{:host => Sham.url, :port => rand(1000) + 1, :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => Sham.username, :password => Sham.password, :system_type => 'smpp', :mt_encodings => ['ascii'], :default_mo_encoding => 'ascii', :mt_csms_method => 'udh' } }
end

TwilioChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:account_sid => Sham.guid, :auth_token => Sham.guid, :from => Sham.number8, :incoming_password => Sham.guid } }
end

TwitterChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "twitter" }
  enabled { true }
  configuration { {:token => Sham.guid, :secret => Sham.guid, :screen_name => Sham.username} }
end

XmppChannel.blueprint do
  account
  name { Sham.guid }
  direction { Channel::Bidirectional }
  protocol { "xmpp" }
  enabled { true }
  configuration { {:user => Sham.username, :domain => Sham.url, :password => Sham.password, :server => Sham.url, :port => 1 + rand(1000), :resource => Sham.username} }
end

Ticket.blueprint do
  code { Sham.number4 }
  secret_key { Sham.guid }
end

Ticket.blueprint :pending do
  status { 'pending' }
end

Country.blueprint do
  name
  iso2 { (1..2).map { ('a'..'z').to_a.rand }.join }
  iso3 { (1..3).map { ('a'..'z').to_a.rand }.join }
  phone_prefix { Sham.number2 }
end
