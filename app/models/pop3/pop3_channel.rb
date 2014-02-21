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

require 'net/pop'

class Pop3Channel < Channel
  include CronChannel

  configuration_accessor :host, :port, :user, :password, :use_ssl, :remove_quoted_text_or_text_after_first_empty_line

  validates_presence_of :host, :user, :password
  validates_numericality_of :port, :greater_than => 0
  handle_password_change

  def self.title
    "POP3"
  end

  def self.default_protocol
    'mailto'
  end

  def check_valid_in_ui
    pop = Net::POP3.new host, port.to_i
    pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if use_ssl.to_b

    begin
      pop.start user, password
      pop.finish
    rescue => e
      errors.add_to_base(e.message)
    end
  end

  def info
    "#{user}@#{host}:#{port}"
  end

  def create_tasks
    create_task 'pop3-receive', POP3_RECEIVE_INTERVAL, ReceivePop3MessageJob.new(account_id, id)
  end

  def destroy_tasks
    drop_task 'pop3-receive'
  end
end
