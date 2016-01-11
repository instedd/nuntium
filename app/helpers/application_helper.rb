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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def short(msg, length = 15)
    return '' if msg.nil?
    msg.length > length ? (msg[0 ... length] + "...") : msg
  end

  def short_html(msg, length = 15)
    ('<span title="' << (h msg) << '">' << h(short(msg, length)) << '</span>').html_safe
  end

  def message_subject(msg)
    if can_view_message?(msg)
      msg.subject
    else
      '*' * (msg.subject.try(:length) || 0)
    end
  end

  def message_body(msg)
    if can_view_message?(msg)
      msg.body
    else
      '*' * (msg.body.try(:length) || 0)
    end
  end

  def can_view_message?(msg)
    return true if account_admin?

    app_access = !msg.application_id || user_applications.find { |ua| ua.application_id == msg.application_id }
    channel_access = msg.channel_id && user_channels.find { |ua| ua.channel_id == msg.channel_id }
    app_access || channel_access
  end

  def time_ago(time)
    return '' if time.nil?
    ('<span title="' << time.utc.to_s << '">' << time_ago_in_words(time.utc, include_seconds: true) << ' ago</span>').html_safe
  end

  def go_back_link
    link_to 'Go back', :controller => :home, :action => :index
  end

  def nuntium_version
    begin
      @@nuntium_version = File.read('VERSION').strip unless defined? @@nuntium_version
    rescue Errno::ENOENT
      @@nuntium_version = 'Development'
    end
    @@nuntium_version
  end
end
