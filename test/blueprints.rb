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

module Fake
  def self.name
    FFaker::Name.name
  end

  def self.email
    FFaker::Internet.email
  end

  def self.username
    FFaker::Internet.user_name
  end

  def self.url
    FFaker::Internet.domain_name
  end

  def self.password
    FFaker::Name.name
  end

  def self.number2
    self.number(2)
  end

  def self.number8
    self.number(8)
  end

  def self.number4
    self.number(4)
  end

  def self.guid
    self.number(10)
  end

  def self.number(n)
    (1..n).map { ('1'..'9').to_a.rand }.join
  end
end

User.blueprint do
  email { Fake.email }
  password { Fake.password }
  password_confirmation { object.password }
  confirmed_at { Time.now - 1.day }
end

Account.blueprint do
  name { Fake.username }
  password { Fake.password }
  password_confirmation { object.password }
end

Application.blueprint do
  name { Fake.username }
  account { Account.make! }
  interface { "rss" }
  password { Fake.password }
  password_confirmation { object.password }
end

Application.blueprint :rss do
end

Application.blueprint :broadcast do
  configuration { {:strategy => 'broadcast'} }
end

[:http_get_callback, :http_post_callback, :qst_client].each do |kind|
  Application.blueprint kind do
    interface { kind.to_s }
    configuration { {:interface_url => Fake.url, :interface_user => Fake.username, :interface_password => Fake.password} }
  end
end

[AoMessage, AtMessage].each do |message|
  message.blueprint do
    from { "sms://#{Fake.number8}" }
    to { "sms://#{Fake.number8}" }
    subject { FFaker::Lorem.sentence }
    body { FFaker::Lorem.paragraph }
    timestamp { Time.at(946702800 + 86400 * rand(100)).getgm }
    guid { Fake.guid }
    state { 'queued' }
  end
  message.blueprint :email do
    from { "mailto://#{Fake.email}" }
    to { "mailto://#{Fake.email}" }
  end
end

Carrier.blueprint do
  country
  name { Fake.name }
  guid { Fake.guid }
  prefixes { Fake.number2 }
end

QstClientChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:url => Fake.url, :user => Fake.username, :password => Fake.password} }
end

QstServerChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  address { Fake.number8 }
  configuration { {:password => 'secret', :password_confirmation => 'secret'} }
end

ClickatellChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:user => Fake.username, :password => Fake.password, :api_id => Fake.guid, :from => Fake.number8, :incoming_password => Fake.password, :cost_per_credit => rand }}
end

DtacChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:user => Fake.username, :password => Fake.password } }
end

IpopChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  address { Fake.number8 }
  configuration { {:mt_post_url => Fake.url, :bid => '1', :cid => Fake.number8 } }
end

MsnChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "msn" }
  enabled { true }
  configuration { {:email => Fake.email, :password => Fake.password } }
end

MultimodemIsmsChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration {{:host => Fake.url, :port => rand(1000) + 1, :user => Fake.username, :password => Fake.password, :time_zone => ActiveSupport::TimeZone.all.rand.name}}
end

Pop3Channel.blueprint do
  account
  name { Fake.guid }
  protocol { "mailto" }
  direction { Channel::Incoming }
  enabled { true }
  configuration { {:host => Fake.url, :port => rand(1000) + 1, :user => Fake.username, :password => Fake.password}}
end

ShujaaChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  address { Fake.number8 }
  configuration { {:username => Fake.username, :password => Fake.password, :shujaa_account => 'live' }}
end

SmtpChannel.blueprint do
  account
  name { Fake.guid }
  protocol { "mailto" }
  direction { Channel::Outgoing }
  enabled { true }
  configuration { {:host => Fake.url, :port => rand(1000) + 1, :user => Fake.username, :password => Fake.password}}
end

SmppChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration {{:host => Fake.url, :port => rand(1000) + 1, :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => Fake.username, :password => Fake.password, :system_type => 'smpp', :mt_encodings => ['ascii'], :default_mo_encoding => 'ascii', :mt_csms_method => 'udh' } }
end

TwilioChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "sms" }
  enabled { true }
  configuration { {:account_sid => Fake.guid, :auth_token => Fake.guid, :from => Fake.number8, :incoming_password => Fake.guid } }
end

TwitterChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "twitter" }
  enabled { true }
  configuration { {:token => Fake.guid, :secret => Fake.guid, :screen_name => Fake.username} }
end

XmppChannel.blueprint do
  account
  name { Fake.guid }
  direction { Channel::Bidirectional }
  protocol { "xmpp" }
  enabled { true }
  configuration { {:user => Fake.username, :domain => Fake.url, :password => Fake.password, :server => Fake.url, :port => 1 + rand(1000), :resource => Fake.username} }
end

Ticket.blueprint do
  code { Fake.number4 }
  secret_key { Fake.guid }
end

Ticket.blueprint :pending do
  status { 'pending' }
end

Country.blueprint do
  name { Fake.name }
  iso2 { (1..2).map { ('a'..'z').to_a.rand }.join }
  iso3 { (1..3).map { ('a'..'z').to_a.rand }.join }
  phone_prefix { Fake.number2 }
end

UserApplication.blueprint do
  user
  application
  account { object.application.account }
end

UserAccount.blueprint do
  user
  account
end

UserChannel.blueprint do
  user
  channel { QstClientChannel.make }
end
