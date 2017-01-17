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

module ReschedulableSendMessageJob
  def reschedule(ex)
    msg = @msg || AoMessage.find(@message_id)
    msg.state = 'delayed'
    msg.save!

    @account.logger.warning :channel_id => @channel.id, :ao_message_id => @message_id, :message => ex.message

    new_job = self.class.new @account_id, @channel_id, @message_id
    ScheduledJob.create! :job => RepublishAoMessageJob.new(@message_id, new_job), :run_at => msg.tries.as_exponential_backoff.minutes.from_now
  end
end
