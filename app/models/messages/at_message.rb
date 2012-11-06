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

class AtMessage < ActiveRecord::Base
  belongs_to :account
  belongs_to :application
  belongs_to :channel
  validates_presence_of :account
  serialize :custom_attributes, Hash

  include MessageCommon
  include MessageGetter
  include MessageSerialization
  include MessageCustomAttributes
  include MessageSearch

  # Logs that each message was delivered/not delivered through the given interface
  def self.log_delivery(msgs, account, interface)
    msgs.each do |msg|
      if msg.tries < account.max_tries
        account.logger.at_message_delivery_succeeded msg, interface
      else
        account.logger.at_message_delivery_exceeded_tries msg, interface
      end
    end
  end

  def send_failed(account, application, exception)
    self.state = 'failed'
    self.save!

    account.logger.exception_in_application_and_at_message application, self, exception
  end

  def token
    guid
  end

  def new_reply(body)
    AoMessage.new :account_id => account_id, :from => to, :to => from, :body => body
  end
end
