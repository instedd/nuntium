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

class Ticket < ActiveRecord::Base

  validates_inclusion_of :status, :in => ['pending', 'complete']
  serialize :data, Hash
  validates_uniqueness_of :code

  def self.checkout(data = nil)
    ticket = Ticket.new({
      :code => Ticket.generate_random_code,
      :secret_key => Guid.new.to_s,
      :expiration => Ticket.get_expiration,
      :data => data,
      :status => 'pending'
    })

    ticket.save!
    ticket
  end

  def self.keep_alive(code, secret_key)
    ticket = Ticket.find_by_code_and_secret_key code, secret_key
    raise "Invalid code or secret key" if ticket.nil?

    ticket.expiration = Ticket.get_expiration

    ticket
  end

  def self.complete(code, data = {})
    ticket = Ticket.find_by_code_and_status code, 'pending'

    raise "Invalid code" if ticket.nil?
    ticket.data = (ticket.data || {}).merge! data
    ticket.status = 'complete'

    ticket.save!
    ticket
  end

  def self.remove_expired
    Ticket.delete_all ['expiration < ?', Time.now.utc]
  end

  def as_json(options = {})
    { :code => code , :secret_key => secret_key, :status => status, :data => (data || {}) }
  end

private

  def self.format_code number
    sprintf "%04d", number
  end

  def self.generate_random_code
    code = rand(9999)
    until Ticket.find_by_code(format_code(code)).nil? do
      code = (code + 1) % 10000
    end
    format_code(code)
  end

  def self.get_expiration
    Time.now.utc + 1.day
  end
end
