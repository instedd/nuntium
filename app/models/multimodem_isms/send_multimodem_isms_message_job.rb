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

class SendMultimodemIsmsMessageJob < SendMessageJob
  def managed_perform
    url = "http://#{@config[:host]}"
    url << ":#{@config[:port]}" if @config[:port].present?
    url << "/sendmsg?"
    url << "user=#{CGI.escape(@config[:user])}&"
    url << "passwd=#{CGI.escape(@config[:password])}&"
    url << "cat=1&"
    url << "to=#{CGI.escape(@msg.to.without_protocol)}&"
    url << "text=#{CGI.escape(@msg.subject_and_body)}"

    response = RestClient.get url
    if response.body[0..2] == "ID:"
      @msg.channel_relative_id = response.body[4..-1]
    elsif response.body[0..3] == "Err:"
      code_with_description = response.body[5..-1]
      code = code_with_description.to_i
      error = MultimodemIsmsChannel::ERRORS[code]

      raise code_with_description if error.nil?
      raise PermanentException.new(Exception.new(code_with_description)) if error[:kind] == :fatal
      raise MessageException.new(Exception.new(code_with_description)) if error[:kind] == :message
      raise code_with_description
    else
      raise response.body
    end
  end
end
