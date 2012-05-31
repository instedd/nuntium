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

require 'xmpp4r/client'

class XmppChannel < Channel
  include ServiceChannel
  include Jabber

  configuration_accessor :user, :password, :domain, :resource, :server, :status
  configuration_accessor :port, :default => 5222

  validates_presence_of :user, :domain, :password
  validates_numericality_of :port, :greater_than => 0

  def self.title
    "XMPP"
  end

  def self.default_protocol
    'xmpp'
  end

  def jid
    jid = "#{user}@#{domain}"
    jid << "/#{resource}" if resource.present?
    jid
  end

  def server
    configuration[:server].presence
  end

  def check_valid_in_ui
    begin
      client = Client::new JID::new(jid)
      client.connect server, port
      client.auth password
    rescue => e
      errors.add_to_base e.message
    ensure
      client.close
    end
  end

  def info
    port_part = port.to_i == 5222 ? '' : ":#{port}"
    "#{user}@#{domain}#{port_part}/#{resource}"
  end
end
