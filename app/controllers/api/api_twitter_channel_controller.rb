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

class ApiTwitterChannelController < ApiAuthenticatedController

  def friendship_create
    channel = @account.channels.find_by_name params[:name]

    return head :not_found unless channel
    return head :forbidden if @application && !channel.application_id
    return head :bad_request if channel.kind != 'twitter'

    user = params[:user]
    follow = params[:follow].to_b

    begin
      result = channel.friendship_create user, follow
    rescue Twitter::TwitterError, Twitter::NotFound, Twitter::InformTwitter, Twitter::Unavailable => e
      index = e.message.index '):'
      code = e.message[1 .. index].to_i
      msg = e.message[index + 2 .. -1].strip
      return render :text => msg, :status => code
    end

    head :ok
  end

end
