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

class SendMsnMessageJob
  include ReschedulableSendMessageJob

  attr_accessor :account_id, :channel_id, :message_id

  def initialize(account_id, channel_id, message_id)
    @account_id = account_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform(delegate)
    @msg = AoMessage.find @message_id

    return true if @msg.channel_id != @channel_id
    return true if @msg.state != 'queued'

    @account = Account.find_by_id @account_id
    @channel = @account.channels.find_by_id @channel_id

    begin
      @msg.tries += 1
      @msg.save!

      delegate.send_message(@msg.id, @msg.from.without_protocol, @msg.to.without_protocol, @msg.subject, @msg.body)
      @msg.send_succeed @account, @channel
    rescue MessageException => e
      @msg.send_failed @account, @channel, e
    end
  end

  def to_s
    "<SendMsnMessageJob:#{@message_id}>"
  end
end
