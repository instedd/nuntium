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

class AbstractPullQstMessageJob
  include CronTask::QuotedTask

  attr_accessor :batch_size

  def perform
    client = QstClient.new *get_url_user_and_password

    options = {:max => batch_size}

    begin
      options[:from_id] = load_last_id if load_last_id

      msgs = client.get_messages options
      msgs = message_class.from_qst msgs

      return if msgs.empty?

      msgs.each { |msg| route msg }

      save_last_id msgs.last.guid
    end while has_quota?
  rescue QstClient::Exception => ex
    if ex.response.code == 401
      on_401 "Pull Qst messages received unauthorized"
    else
      on_exception "Pull Qst messages received response code #{ex.response.code}"
    end
  end
end
