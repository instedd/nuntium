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

class TicketsController < ApplicationController
  skip_before_action :check_login

  def create
    Ticket.remove_expired

    ticket = Ticket.checkout clean_params
    render :json => ticket.to_json
  end

  def show
    begin
      ticket = Ticket.keep_alive params[:code], params[:secret_key]
    rescue RuntimeError
      return head :not_found
    end
    render :json => ticket.to_json
  end

private

  def clean_params
    r = params.reject { |k,v| [:action,:controller,:format].include?(k.to_sym) }
    r.symbolize_keys
  end
end
