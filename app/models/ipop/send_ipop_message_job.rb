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

class SendIpopMessageJob < SendMessageJob
  def managed_perform
    data = {
      :hp => @msg.to.mobile_number,
      :ts => @msg.timestamp.strftime('%Y%m%d%H%M%S') + ("%03d" % @msg.timestamp.milliseconds),
      :bid => @config[:bid],
      :cid => @config[:cid],
      :mt => 1,
      :txt => @msg.subject_and_body,
      :sc => @channel.address
    }

    options = {:headers => {:content_type => "application/x-www-form-urlencoded"}}

    res = RestClient::Resource.new(@config[:mt_post_url], options)
    res = res.post data
    netres = res.net_http_res

    case netres
      when Net::HTTPSuccess, Net::HTTPRedirection
        raise res.body if res.body.blank? || res.body.strip != 'OK'

        @msg.channel_relative_id = "#{@msg.to.mobile_number}-#{data[:ts]}"
      else
        raise netres.error!
    end
  end
end
