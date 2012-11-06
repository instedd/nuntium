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

# Generic job to send a message via a channel.
# Subclasses must implement managed_perform.
class SendMessageJob
  include ReschedulableSendMessageJob

  attr_accessor :account_id, :channel_id, :message_id

  def initialize(account_id, channel_id, message_id)
    @account_id = account_id
    @channel_id = channel_id
    @message_id = message_id
  end

  def perform
    begin
      @msg = AoMessage.find @message_id

      return true if @msg.channel_id != @channel_id
      return true if @msg.state != 'queued'

      @account = Account.find_by_id @account_id
      @channel = @account.channels.find_by_id @channel_id
      @config = @channel.configuration

      @msg.tries += 1
      @msg.save!

      managed_perform

      @msg.send_succeed @account, @channel
    rescue MessageException => ex
      @msg.send_failed @account, @channel, ex.inner
    rescue PermanentException => ex
      alert_msg = "Permanent exception when trying to send message with id #{@msg.id}: #{ex}"
      @channel.alert alert_msg
      raise alert_msg
    end
  end

  # Should send the message.
  # If there's a failure, one of these exceptions
  # should be thrown:
  #  - MessageException: intrinsic to the message
  #  - PermanentException: like "the password is wrong"
  #  - Exception: like "we don't have an internet connection" (temporary or unknown exception)
  # If there's no error, @msg.send_succeed(@account, @channel) will be invoked by this class
  def managed_perform
    raise PermanentException.new(Exception.new("managed_perform method is not implemented for #{self.class.name}"))
  end

  def to_s
    "<#{self.class}:#{@message_id}>"
  end
end
