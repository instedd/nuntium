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

class ApiXmppChannelController < ApiAuthenticatedController
  before_action :require_account!

  def add_contact
    channel = @account.channels.find_by_name params[:name]

    return head :not_found unless channel
    return head :forbidden if @application && !channel.application_id
    return head :bad_request if channel.kind != 'xmpp'
    return head :bad_request if params[:jid].blank?

    channel.add_contact params[:jid]

    head :ok
  end
end
