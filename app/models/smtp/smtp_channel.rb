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

require 'net/smtp'

class SmtpChannel < Channel
  include GenericChannel

  configuration_accessor :host, :port, :user, :password, :use_ssl

  validates_presence_of :host
  validates_numericality_of :port, :greater_than => 0

  handle_password_change

  def self.title
    "SMTP"
  end

  def self.default_protocol
    'mailto'
  end

  def check_valid_in_ui
    smtp = Net::SMTP.new host, port.to_i
    smtp.enable_tls if use_ssl.to_b

    begin
      smtp.start 'localhost.localdomain', user, password
      smtp.finish
    rescue => e
      errors.add_to_base e.message
    end
  end

  def info
    "#{user}@#{host}:#{port}"
  end
end
